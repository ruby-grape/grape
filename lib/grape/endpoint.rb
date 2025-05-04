# frozen_string_literal: true

module Grape
  # An Endpoint is the proxy scope in which all routing
  # blocks are executed. In other words, any methods
  # on the instance level of this class may be called
  # from inside a `get`, `post`, etc.
  class Endpoint
    extend Forwardable
    include Grape::DSL::Settings
    include Grape::DSL::InsideRoute

    attr_accessor :block, :source, :options
    attr_reader :env, :request

    def_delegators :request, :params, :headers, :cookies
    def_delegator :cookies, :response_cookies

    class << self
      def new(...)
        self == Endpoint ? Class.new(Endpoint).new(...) : super
      end

      def before_each(new_setup = false, &block)
        @before_each ||= []
        if new_setup == false
          return @before_each unless block

          @before_each << block
        else
          @before_each = [new_setup]
        end
      end

      def run_before_each(endpoint)
        superclass.run_before_each(endpoint) unless self == Endpoint
        before_each.each { |blk| blk.try(:call, endpoint) }
      end

      # @api private
      #
      # Create an UnboundMethod that is appropriate for executing an endpoint
      # route.
      #
      # The unbound method allows explicit calls to +return+ without raising a
      # +LocalJumpError+. The method will be removed, but a +Proc+ reference to
      # it will be returned. The returned +Proc+ expects a single argument: the
      # instance of +Endpoint+ to bind to the method during the call.
      #
      # @param [String, Symbol] method_name
      # @return [Proc]
      # @raise [NameError] an instance method with the same name already exists
      def generate_api_method(method_name, &block)
        raise NameError.new("method #{method_name.inspect} already exists and cannot be used as an unbound method name") if method_defined?(method_name)

        define_method(method_name, &block)
        method = instance_method(method_name)
        remove_method(method_name)

        proc do |endpoint_instance|
          ActiveSupport::Notifications.instrument('endpoint_render.grape', endpoint: endpoint_instance) do
            method.bind_call(endpoint_instance)
          end
        end
      end
    end

    # Create a new endpoint.
    # @param new_settings [InheritableSetting] settings to determine the params,
    #   validations, and other properties from.
    # @param options [Hash] attributes of this endpoint
    # @option options path [String or Array] the path to this endpoint, within
    #   the current scope.
    # @option options method [String or Array] which HTTP method(s) can be used
    #   to reach this endpoint.
    # @option options route_options [Hash]
    # @note This happens at the time of API definition, so in this context the
    # endpoint does not know if it will be mounted under a different endpoint.
    # @yield a block defining what your API should do when this endpoint is hit
    def initialize(new_settings, options = {}, &block)
      require_option(options, :path)
      require_option(options, :method)

      self.inheritable_setting = new_settings.point_in_time_copy

      # now +namespace_stackable(:declared_params)+ contains all params defined for
      # this endpoint and its parents, but later it will be cleaned up,
      # see +reset_validations!+ in lib/grape/dsl/validations.rb
      route_setting(:declared_params, namespace_stackable(:declared_params).flatten)
      route_setting(:saved_validations, namespace_stackable(:validations))

      namespace_stackable(:representations, []) unless namespace_stackable(:representations)
      namespace_inheritable(:default_error_status, 500) unless namespace_inheritable(:default_error_status)

      @options = options

      @options[:path] = Array(options[:path])
      @options[:path] << '/' if options[:path].empty?

      @options[:method] = Array(options[:method])
      @options[:route_options] ||= {}

      @lazy_initialize_lock = Mutex.new
      @lazy_initialized = nil
      @block = nil

      @status = nil
      @stream = nil
      @body = nil
      @proc = nil

      return unless block

      @source = block
      @block = self.class.generate_api_method(method_name, &block)
    end

    # Update our settings from a given set of stackable parameters. Used when
    # the endpoint's API is mounted under another one.
    def inherit_settings(namespace_stackable)
      parent_validations = namespace_stackable[:validations]
      inheritable_setting.route[:saved_validations].concat(parent_validations) if parent_validations.any?
      parent_declared_params = namespace_stackable[:declared_params]
      inheritable_setting.route[:declared_params].concat(parent_declared_params.flatten) if parent_declared_params.any?

      endpoints&.each { |e| e.inherit_settings(namespace_stackable) }
    end

    def require_option(options, key)
      raise Grape::Exceptions::MissingOption.new(key) unless options.key?(key)
    end

    def method_name
      [options[:method],
       Namespace.joined_space(namespace_stackable(:namespace)),
       (namespace_stackable(:mount_path) || []).join('/'),
       options[:path].join('/')]
        .join(' ')
    end

    def routes
      @routes ||= endpoints&.collect(&:routes)&.flatten || to_routes
    end

    def reset_routes!
      endpoints&.each(&:reset_routes!)
      @namespace = nil
      @routes = nil
    end

    def mount_in(router)
      return endpoints.each { |e| e.mount_in(router) } if endpoints

      reset_routes!
      routes.each do |route|
        router.append(route.apply(self))
        next unless !namespace_inheritable(:do_not_route_head) && route.request_method == Rack::GET

        route.dup.then do |head_route|
          head_route.convert_to_head_request!
          router.append(head_route.apply(self))
        end
      end
    end

    def to_routes
      default_route_options = prepare_default_route_attributes

      map_routes do |method, raw_path|
        prepared_path = Path.new(raw_path, namespace, prepare_default_path_settings)
        params = options[:route_options].present? ? options[:route_options].merge(default_route_options) : default_route_options
        route = Grape::Router::Route.new(method, prepared_path.origin, prepared_path.suffix, params)
        route.apply(self)
      end.flatten
    end

    def prepare_routes_requirements
      {}.merge!(*namespace_stackable(:namespace).map(&:requirements)).tap do |requirements|
        endpoint_requirements = options.dig(:route_options, :requirements)
        requirements.merge!(endpoint_requirements) if endpoint_requirements
      end
    end

    def prepare_default_route_attributes
      {
        namespace: namespace,
        version: prepare_version,
        requirements: prepare_routes_requirements,
        prefix: namespace_inheritable(:root_prefix),
        anchor: options[:route_options].fetch(:anchor, true),
        settings: inheritable_setting.route.except(:declared_params, :saved_validations),
        forward_match: options[:forward_match]
      }
    end

    def prepare_version
      version = namespace_inheritable(:version)
      return if version.blank?

      version.length == 1 ? version.first : version
    end

    def map_routes
      options[:method].map { |method| options[:path].map { |path| yield method, path } }
    end

    def prepare_default_path_settings
      namespace_stackable_hash = inheritable_setting.namespace_stackable.to_hash
      namespace_inheritable_hash = inheritable_setting.namespace_inheritable.to_hash
      namespace_stackable_hash.merge!(namespace_inheritable_hash)
    end

    def namespace
      @namespace ||= Namespace.joined_space_path(namespace_stackable(:namespace))
    end

    def call(env)
      lazy_initialize!
      dup.call!(env)
    end

    def call!(env)
      env[Grape::Env::API_ENDPOINT] = self
      @env = env
      @app.call(env)
    end

    # Return the collection of endpoints within this endpoint.
    # This is the case when an Grape::API mounts another Grape::API.
    def endpoints
      @endpoints ||= options[:app].try(:endpoints)
    end

    def equals?(endpoint)
      (options == endpoint.options) && (inheritable_setting.to_hash == endpoint.inheritable_setting.to_hash)
    end

    # The purpose of this override is solely for stripping internals when an error occurs while calling
    # an endpoint through an api. See https://github.com/ruby-grape/grape/issues/2398
    # Otherwise, it calls super.
    def inspect
      return super unless env

      "#{self.class} in '#{route.origin}' endpoint"
    end

    protected

    def run
      ActiveSupport::Notifications.instrument('endpoint_run.grape', endpoint: self, env: env) do
        @request = Grape::Request.new(env, build_params_with: namespace_inheritable(:build_params_with))
        begin
          self.class.run_before_each(self)
          run_filters befores, :before

          if env.key?(Grape::Env::GRAPE_ALLOWED_METHODS)
            header['Allow'] = env[Grape::Env::GRAPE_ALLOWED_METHODS].join(', ')
            raise Grape::Exceptions::MethodNotAllowed.new(header) unless options?

            header 'Allow', header['Allow']
            response_object = ''
            status 204
          else
            run_filters before_validations, :before_validation
            run_validators validations, request
            run_filters after_validations, :after_validation
            response_object = execute
          end

          run_filters afters, :after
          build_response_cookies

          # status verifies body presence when DELETE
          @body ||= response_object

          # The body commonly is an Array of Strings, the application instance itself, or a Stream-like object
          response_object = stream || [body]

          [status, header, response_object]
        ensure
          run_filters finallies, :finally
        end
      end
    end

    def execute
      @block&.call(self)
    end

    def helpers
      lazy_initialize! && @helpers
    end

    def lazy_initialize!
      return true if @lazy_initialized

      @lazy_initialize_lock.synchronize do
        return true if @lazy_initialized

        @helpers = build_helpers&.tap { |mod| self.class.include mod }
        @app = options[:app] || build_stack(@helpers)

        @lazy_initialized = true
      end
    end

    def run_validators(validators, request)
      validation_errors = []

      ActiveSupport::Notifications.instrument('endpoint_run_validators.grape', endpoint: self, validators: validators, request: request) do
        validators.each do |validator|
          validator.validate(request)
        rescue Grape::Exceptions::Validation => e
          validation_errors << e
          break if validator.fail_fast?
        rescue Grape::Exceptions::ValidationArrayErrors => e
          validation_errors.concat e.errors
          break if validator.fail_fast?
        end
      end

      validation_errors.any? && raise(Grape::Exceptions::ValidationErrors.new(errors: validation_errors, headers: header))
    end

    def run_filters(filters, type = :other)
      ActiveSupport::Notifications.instrument('endpoint_run_filters.grape', endpoint: self, filters: filters, type: type) do
        filters&.each { |filter| instance_eval(&filter) }
      end
      post_extension = DSL::InsideRoute.post_filter_methods(type)
      extend post_extension if post_extension
    end

    %i[befores before_validations after_validations afters finallies].each do |method|
      define_method method do
        namespace_stackable(method)
      end
    end

    def validations
      return enum_for(:validations) unless block_given?

      route_setting(:saved_validations)&.each do |saved_validation|
        yield Grape::Validations::ValidatorFactory.create_validator(saved_validation)
      end
    end

    def options?
      options[:options_route_enabled] &&
        env[Rack::REQUEST_METHOD] == Rack::OPTIONS
    end

    private

    def build_stack(helpers)
      stack = Grape::Middleware::Stack.new

      content_types = namespace_stackable_with_hash(:content_types)
      format = namespace_inheritable(:format)

      stack.use Rack::Head
      stack.use Rack::Lint if lint?
      stack.use Class.new(Grape::Middleware::Error),
                helpers: helpers,
                format: format,
                content_types: content_types,
                default_status: namespace_inheritable(:default_error_status),
                rescue_all: namespace_inheritable(:rescue_all),
                rescue_grape_exceptions: namespace_inheritable(:rescue_grape_exceptions),
                default_error_formatter: namespace_inheritable(:default_error_formatter),
                error_formatters: namespace_stackable_with_hash(:error_formatters),
                rescue_options: namespace_stackable_with_hash(:rescue_options),
                rescue_handlers: namespace_reverse_stackable_with_hash(:rescue_handlers),
                base_only_rescue_handlers: namespace_stackable_with_hash(:base_only_rescue_handlers),
                all_rescue_handler: namespace_inheritable(:all_rescue_handler),
                grape_exceptions_rescue_handler: namespace_inheritable(:grape_exceptions_rescue_handler)

      stack.concat namespace_stackable(:middleware)

      if namespace_inheritable(:version).present?
        stack.use Grape::Middleware::Versioner.using(namespace_inheritable(:version_options)[:using]),
                  versions: namespace_inheritable(:version).flatten,
                  version_options: namespace_inheritable(:version_options),
                  prefix: namespace_inheritable(:root_prefix),
                  mount_path: namespace_stackable(:mount_path).first
      end

      stack.use Grape::Middleware::Formatter,
                format: format,
                default_format: namespace_inheritable(:default_format) || :txt,
                content_types: content_types,
                formatters: namespace_stackable_with_hash(:formatters),
                parsers: namespace_stackable_with_hash(:parsers)

      builder = stack.build
      builder.run ->(env) { env[Grape::Env::API_ENDPOINT].run }
      builder.to_app
    end

    def build_helpers
      helpers = namespace_stackable(:helpers)
      return if helpers.empty?

      Module.new { helpers.each { |mod_to_include| include mod_to_include } }
    end

    def build_response_cookies
      response_cookies do |name, value|
        cookie_value = value.is_a?(Hash) ? value : { value: value }
        Rack::Utils.set_cookie_header! header, name, cookie_value
      end
    end

    def lint?
      namespace_inheritable(:lint) || Grape.config.lint
    end
  end
end
