# frozen_string_literal: true

module Grape
  # An Endpoint is the proxy scope in which all routing
  # blocks are executed. In other words, any methods
  # on the instance level of this class may be called
  # from inside a `get`, `post`, etc.
  class Endpoint
    extend Forwardable
    include Grape::DSL::Settings
    include Grape::DSL::Headers
    include Grape::DSL::InsideRoute

    attr_reader :env, :request, :source, :options

    def_delegators :request, :params, :headers, :cookies
    def_delegator :cookies, :response_cookies

    class << self
      def before_each(new_setup = false, &block)
        @before_each ||= []
        if new_setup == false
          return @before_each unless block

          @before_each << block
        elsif new_setup
          @before_each = [new_setup]
        else
          @before_each.clear
        end
      end

      def run_before_each(endpoint)
        superclass.run_before_each(endpoint) unless self == Endpoint
        before_each.each { |blk| blk.call(endpoint) }
      end

      def block_to_unbound_method(block)
        return unless block

        define_method :temp_unbound_method, block
        method = instance_method(:temp_unbound_method)
        remove_method :temp_unbound_method
        method
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
    def initialize(new_settings, **options, &block)
      self.inheritable_setting = new_settings.point_in_time_copy

      # now +namespace_stackable(:declared_params)+ contains all params defined for
      # this endpoint and its parents, but later it will be cleaned up,
      # see +reset_validations!+ in lib/grape/dsl/validations.rb
      inheritable_setting.route[:declared_params] = inheritable_setting.namespace_stackable[:declared_params].flatten
      inheritable_setting.route[:saved_validations] = inheritable_setting.namespace_stackable[:validations]

      inheritable_setting.namespace_stackable[:representations] = [] unless inheritable_setting.namespace_stackable[:representations]
      inheritable_setting.namespace_inheritable[:default_error_status] = 500 unless inheritable_setting.namespace_inheritable[:default_error_status]

      @options = options

      @options[:path] = Array(options[:path])
      @options[:path] << '/' if options[:path].empty?
      @options[:method] = Array(options[:method])

      @status = nil
      @stream = nil
      @body = nil
      @source = self.class.block_to_unbound_method(block)
      @before_filter_passed = false
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

    def routes
      @routes ||= endpoints&.collect(&:routes)&.flatten || to_routes
    end

    def reset_routes!
      endpoints&.each(&:reset_routes!)
      @namespace = nil
      @routes = nil
    end

    def mount_in(router)
      if endpoints
        compile!
        return endpoints.each { |e| e.mount_in(router) }
      end

      reset_routes!
      compile!
      routes.each do |route|
        router.append(route.apply(self))
        next unless !inheritable_setting.namespace_inheritable[:do_not_route_head] && route.request_method == Rack::GET

        route.dup.then do |head_route|
          head_route.convert_to_head_request!
          router.append(head_route.apply(self))
        end
      end
    end

    def namespace
      @namespace ||= Namespace.joined_space_path(inheritable_setting.namespace_stackable[:namespace])
    end

    def call(env)
      dup.call!(env)
    end

    def call!(env)
      env[Grape::Env::API_ENDPOINT] = self
      @env = env
      # this adds the helpers only to the instance
      singleton_class.include(@helpers) if @helpers
      @app.call(env)
    end

    # Return the collection of endpoints within this endpoint.
    # This is the case when an Grape::API mounts another Grape::API.
    def endpoints
      @endpoints ||= options[:app].respond_to?(:endpoints) ? options[:app].endpoints : nil
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
        @request = Grape::Request.new(env, build_params_with: inheritable_setting.namespace_inheritable[:build_params_with])
        begin
          self.class.run_before_each(self)
          run_filters befores, :before
          @before_filter_passed = true

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
      return unless @source

      ActiveSupport::Notifications.instrument('endpoint_render.grape', endpoint: self) do
        @source.bind_call(self)
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
      return unless filters

      ActiveSupport::Notifications.instrument('endpoint_run_filters.grape', endpoint: self, filters: filters, type: type) do
        filters.each { |filter| instance_eval(&filter) }
      end
    end

    %i[befores before_validations after_validations afters finallies].each do |method|
      define_method method do
        inheritable_setting.namespace_stackable[method]
      end
    end

    def validations
      saved_validations = inheritable_setting.route[:saved_validations]
      return if saved_validations.nil?
      return enum_for(:validations) unless block_given?

      saved_validations.each do |saved_validation|
        yield Grape::Validations::ValidatorFactory.create_validator(saved_validation)
      end
    end

    def options?
      options[:options_route_enabled] &&
        env[Rack::REQUEST_METHOD] == Rack::OPTIONS
    end

    private

    attr_reader :before_filter_passed

    def compile!
      @app = options[:app] || build_stack
      @helpers = build_helpers
    end

    def to_routes
      route_options = options[:route_options]
      default_route_options = prepare_default_route_attributes(route_options)
      complete_route_options = route_options.merge(default_route_options)
      path_settings = prepare_default_path_settings

      options[:method].flat_map do |method|
        options[:path].map do |path|
          prepared_path = Path.new(path, default_route_options[:namespace], path_settings)
          pattern = Grape::Router::Pattern.new(
            origin: prepared_path.origin,
            suffix: prepared_path.suffix,
            anchor: default_route_options[:anchor],
            params: route_options[:params],
            format: options[:format],
            version: default_route_options[:version],
            requirements: default_route_options[:requirements]
          )
          Grape::Router::Route.new(self, method, pattern, complete_route_options)
        end
      end
    end

    def prepare_default_route_attributes(route_options)
      {
        namespace: namespace,
        version: prepare_version(inheritable_setting.namespace_inheritable[:version]),
        requirements: prepare_routes_requirements(route_options[:requirements]),
        prefix: inheritable_setting.namespace_inheritable[:root_prefix],
        anchor: route_options.fetch(:anchor, true),
        settings: inheritable_setting.route.except(:declared_params, :saved_validations),
        forward_match: options[:forward_match]
      }
    end

    def prepare_default_path_settings
      namespace_stackable_hash = inheritable_setting.namespace_stackable.to_hash
      namespace_inheritable_hash = inheritable_setting.namespace_inheritable.to_hash
      namespace_stackable_hash.merge!(namespace_inheritable_hash)
    end

    def prepare_routes_requirements(route_options_requirements)
      namespace_requirements = inheritable_setting.namespace_stackable[:namespace].filter_map(&:requirements)
      namespace_requirements << route_options_requirements if route_options_requirements.present?
      namespace_requirements.reduce({}, :merge)
    end

    def prepare_version(namespace_inheritable_version)
      return if namespace_inheritable_version.blank?

      namespace_inheritable_version.length == 1 ? namespace_inheritable_version.first : namespace_inheritable_version
    end

    def build_stack
      stack = Grape::Middleware::Stack.new

      content_types = inheritable_setting.namespace_stackable_with_hash(:content_types)
      format = inheritable_setting.namespace_inheritable[:format]

      stack.use Rack::Head
      stack.use Rack::Lint if lint?
      stack.use Grape::Middleware::Error,
                format: format,
                content_types: content_types,
                default_status: inheritable_setting.namespace_inheritable[:default_error_status],
                rescue_all: inheritable_setting.namespace_inheritable[:rescue_all],
                rescue_grape_exceptions: inheritable_setting.namespace_inheritable[:rescue_grape_exceptions],
                default_error_formatter: inheritable_setting.namespace_inheritable[:default_error_formatter],
                error_formatters: inheritable_setting.namespace_stackable_with_hash(:error_formatters),
                rescue_options: inheritable_setting.namespace_stackable_with_hash(:rescue_options),
                rescue_handlers: rescue_handlers,
                base_only_rescue_handlers: inheritable_setting.namespace_stackable_with_hash(:base_only_rescue_handlers),
                all_rescue_handler: inheritable_setting.namespace_inheritable[:all_rescue_handler],
                grape_exceptions_rescue_handler: inheritable_setting.namespace_inheritable[:grape_exceptions_rescue_handler]

      stack.concat inheritable_setting.namespace_stackable[:middleware]

      if inheritable_setting.namespace_inheritable[:version].present?
        stack.use Grape::Middleware::Versioner.using(inheritable_setting.namespace_inheritable[:version_options][:using]),
                  versions: inheritable_setting.namespace_inheritable[:version].flatten,
                  version_options: inheritable_setting.namespace_inheritable[:version_options],
                  prefix: inheritable_setting.namespace_inheritable[:root_prefix],
                  mount_path: inheritable_setting.namespace_stackable[:mount_path].first
      end

      stack.use Grape::Middleware::Formatter,
                format: format,
                default_format: inheritable_setting.namespace_inheritable[:default_format] || :txt,
                content_types: content_types,
                formatters: inheritable_setting.namespace_stackable_with_hash(:formatters),
                parsers: inheritable_setting.namespace_stackable_with_hash(:parsers)

      builder = stack.build
      builder.run ->(env) { env[Grape::Env::API_ENDPOINT].run }
      builder.to_app
    end

    def build_helpers
      helpers = inheritable_setting.namespace_stackable[:helpers]
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
      inheritable_setting.namespace_inheritable[:lint] || Grape.config.lint
    end

    def rescue_handlers
      rescue_handlers = inheritable_setting.namespace_reverse_stackable[:rescue_handlers]
      return if rescue_handlers.blank?

      rescue_handlers.each_with_object({}) do |rescue_handler, result|
        result.merge!(rescue_handler) { |_k, s1, _s2| s1 }
      end
    end
  end
end
