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

    attr_reader :env, :request, :source, :options, :endpoints
    attr_accessor :options_route_enabled

    def_delegators :request, :params, :headers, :cookies
    def_delegator :cookies, :response_cookies

    # The API (a +Grape::API+ instance) this endpoint belongs to.
    def_delegator :@config, :api

    # The logger configured on the API this endpoint belongs to. Available
    # inside route handlers, +before+/+after+/+after_validation+/+finally+
    # filters, and +rescue_from+ blocks.
    def_delegator :api, :logger

    # The Rack app or Grape API mounted at this endpoint, or +nil+ for a plain
    # block endpoint. Prefer this over +options[:app]+, which is retained only
    # for backwards compatibility.
    def mounted_app
      config.app
    end

    class << self
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
    # @param http_methods [String or Array] which HTTP method(s) can be used to
    #   reach this endpoint.
    # @param path [String or Array] the path to this endpoint, within the
    #   current scope.
    # @param api [Grape::API] the API this endpoint belongs to. Exposed as
    #   {#api}.
    # @param app [#call, nil] the Rack app or Grape API mounted at this
    #   endpoint; +nil+ for a plain block endpoint. Exposed as {#mounted_app}.
    # @param params [Hash] the declared params for this endpoint, keyed by name.
    #   Kept out of +route_options+ and read via +config.params+.
    # @param requirements [Hash, nil] regular-expression constraints for named
    #   path params. Read via +config.requirements+.
    # @param anchor [Boolean] whether the route anchors to the whole path
    #   (default +true+). Read via +config.anchor+.
    # @param options [Hash] attributes of this endpoint, normalized into a
    #   +Grape::Endpoint::Options+ value object.
    # @option options route_options [Hash]
    # @note This happens at the time of API definition, so in this context the
    # endpoint does not know if it will be mounted under a different endpoint.
    # @yield a block defining what your API should do when this endpoint is hit
    def initialize(new_settings, http_methods:, path:, api:, app: nil, params: {}, requirements: nil, anchor: true, **options, &block)
      self.inheritable_setting = new_settings.point_in_time_copy

      # now +namespace_stackable(:declared_params)+ contains all params defined for
      # this endpoint and its parents, but later it will be cleaned up,
      # see +reset_validations!+ in lib/grape/dsl/validations.rb
      inheritable_setting.route[:declared_params] = inheritable_setting.namespace_stackable[:declared_params].flatten
      inheritable_setting.route[:saved_validations] = inheritable_setting.namespace_stackable[:validations].dup

      inheritable_setting.namespace_stackable[:representations] ||= []
      inheritable_setting.namespace_inheritable[:default_error_status] ||= 500

      @options = options
      @config = Options.new(http_methods:, path:, api:, app:, params:, requirements:, anchor:, **options)
      # +:app+ is still surfaced on the public options Hash for backwards
      # compatibility (e.g. grape-swagger); prefer the +mounted_app+ reader.
      @options[:app] = app if app

      @status = nil
      @stream = nil
      @body = nil
      @source = self.class.block_to_unbound_method(block)
      @before_filter_passed = false
      @options_route_enabled = false
      @endpoints = @config.app.endpoints if @config.app.respond_to?(:endpoints)
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
      @routes ||= endpoints&.flat_map(&:routes) || to_routes
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
        next if inheritable_setting.namespace_inheritable[:do_not_route_head] || route.request_method != Rack::GET

        router.append(route.to_head.apply(self))
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

    def ==(other)
      other.is_a?(self.class) &&
        config == other.config &&
        inheritable_setting == other.inheritable_setting
    end
    alias eql? ==

    # The purpose of this override is solely for stripping internals when an error occurs while calling
    # an endpoint through an api. See https://github.com/ruby-grape/grape/issues/2398
    # Otherwise, it calls super.
    def inspect
      return super unless env

      "#{self.class} in '#{route.origin}' endpoint"
    end

    protected

    def run
      instrument_run do
        @request = Grape::Request.new(env, build_params_with: @build_params_with)
        begin
          run_filters befores, :before
          @before_filter_passed = true

          if env.key?(Grape::Env::GRAPE_ALLOWED_METHODS)
            header['Allow'] = env[Grape::Env::GRAPE_ALLOWED_METHODS].join(', ')
            raise Grape::Exceptions::MethodNotAllowed.new(header) unless options?

            response_object = ''
            status 204
          else
            run_filters before_validations, :before_validation
            run_validators(request:)
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
      return unless source

      instrument_render do
        source.bind_call(self)
      end
    end

    def run_validators(request:)
      validators = inheritable_setting.route[:saved_validations]
      return if validators.blank?

      validation_exceptions = nil

      Grape::Validations::ParamScopeTracker.track do
        instrument_run_validators(validators, request) do
          validators.each do |validator|
            validator.validate(request)
          rescue Grape::Exceptions::Validation, Grape::Exceptions::ValidationArrayErrors => e
            (validation_exceptions ||= []) << e
            break if validator.fail_fast?
          end
        end
      end

      raise Grape::Exceptions::ValidationErrors.new(exceptions: validation_exceptions, headers: header) if validation_exceptions
    end

    def run_filters(filters, type = :other)
      return if filters.blank?

      instrument_run_filters(filters, type) do
        filters.each { |filter| instance_eval(&filter) }
      end
    end

    attr_reader :befores, :before_validations, :after_validations, :afters, :finallies, :config

    def options?
      options_route_enabled && env[Rack::REQUEST_METHOD] == Rack::OPTIONS
    end

    private

    attr_reader :before_filter_passed

    # Instrument helpers. Each guards on +listening?+ so that with no subscriber
    # the payload Hash and notification machinery are skipped and the block runs
    # directly (no added allocations); the block is forwarded anonymously so
    # nothing is allocated unless a subscriber is present.
    def instrument_run(&)
      return yield unless ActiveSupport::Notifications.notifier.listening?('endpoint_run.grape')

      ActiveSupport::Notifications.instrument('endpoint_run.grape', endpoint: self, env:, &)
    end

    def instrument_render(&)
      return yield unless ActiveSupport::Notifications.notifier.listening?('endpoint_render.grape')

      ActiveSupport::Notifications.instrument('endpoint_render.grape', endpoint: self, &)
    end

    def instrument_run_validators(validators, request, &)
      return yield unless ActiveSupport::Notifications.notifier.listening?('endpoint_run_validators.grape')

      ActiveSupport::Notifications.instrument('endpoint_run_validators.grape', endpoint: self, validators:, request:, &)
    end

    def instrument_run_filters(filters, type, &)
      return yield unless ActiveSupport::Notifications.notifier.listening?('endpoint_run_filters.grape')

      ActiveSupport::Notifications.instrument('endpoint_run_filters.grape', endpoint: self, filters:, type:, &)
    end

    def compile!
      @app = config.app || build_stack
      warn_unauthenticated_mounted_app
      @helpers = build_helpers
      stackable = inheritable_setting.namespace_stackable
      @befores            = stackable[:befores]
      @before_validations = stackable[:before_validations]
      @after_validations  = stackable[:after_validations]
      @afters             = stackable[:afters]
      @finallies          = stackable[:finallies]
      @build_params_with  = inheritable_setting.namespace_inheritable[:build_params_with]
    end

    def to_routes
      route_options = config.route_options
      params = config.params
      path_settings = prepare_default_path_settings
      forward_match = bare_rack_app?
      version = prepare_version(inheritable_setting.namespace_inheritable[:version])
      prefix = inheritable_setting.namespace_inheritable[:root_prefix]
      requirements = prepare_routes_requirements(config.requirements)
      anchor = config.anchor
      settings = inheritable_setting.route.except(:declared_params, :saved_validations)

      config.http_methods.flat_map do |method|
        config.path.map do |path|
          pattern = Grape::Router::Pattern.build(
            path:,
            namespace:,
            settings: path_settings,
            anchor:,
            params:,
            version:,
            requirements:
          )
          Grape::Router::Route.new(self, method, pattern, route_options, forward_match:, params:, namespace:, prefix:, settings:)
        end
      end
    end

    # True when a bare Rack app (anything that isn't a Grape app) is mounted at
    # this endpoint. Such an app is called directly and matched by path prefix
    # rather than an anchored route.
    def bare_rack_app?
      config.app && !config.app.is_a?(Grape::Mountable)
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

      content_types = inheritable_setting.content_types
      format = inheritable_setting.namespace_inheritable[:format]

      stack.use Rack::Head
      stack.use Rack::Lint if lint?
      stack.use Grape::Middleware::Error, **error_middleware_options(format, content_types)

      stack.concat inheritable_setting.namespace_stackable[:middleware]

      if inheritable_setting.namespace_inheritable[:version].present?
        version_options = inheritable_setting.namespace_inheritable[:version_options]
        stack.use Grape::Middleware::Versioner.using(version_options.using),
                  versions: inheritable_setting.namespace_inheritable[:version].flatten,
                  version_options:,
                  prefix: inheritable_setting.namespace_inheritable[:root_prefix],
                  mount_path: inheritable_setting.namespace_stackable[:mount_path].first
      end

      stack.use Grape::Middleware::Formatter,
                format:,
                default_format: inheritable_setting.namespace_inheritable[:default_format] || :txt,
                content_types:,
                formatters: inheritable_setting.formatters,
                parsers: inheritable_setting.parsers

      builder = stack.build
      builder.run ->(env) { env[Grape::Env::API_ENDPOINT].run }
      builder.to_app
    end

    def error_middleware_options(format, content_types)
      ns_inh = inheritable_setting.namespace_inheritable
      ns_stack = inheritable_setting
      {
        format:,
        content_types:,
        default_status: ns_inh[:default_error_status],
        rescue_all: ns_inh[:rescue_all],
        rescue_grape_exceptions: ns_inh[:rescue_grape_exceptions],
        default_error_formatter: ns_inh[:default_error_formatter],
        error_formatters: ns_stack.error_formatters,
        rescue_options: ns_stack.namespace_stackable[:rescue_options]&.last,
        rescue_handlers: ns_stack.rescue_handlers,
        base_only_rescue_handlers: ns_stack.base_only_rescue_handlers,
        all_rescue_handler: ns_inh[:all_rescue_handler],
        grape_exceptions_rescue_handler: ns_inh[:grape_exceptions_rescue_handler],
        internal_grape_exceptions_rescue_handler: ns_inh[:internal_grape_exceptions_rescue_handler]
      }
    end

    def build_helpers
      helpers = inheritable_setting.namespace_stackable[:helpers]
      return if helpers.empty?

      Module.new { helpers.each { |mod_to_include| include mod_to_include } }
    end

    # A bare Rack app mounted with +mount+ is called directly (see +compile!+):
    # it does not go through +build_stack+, so the API's authentication
    # middleware never runs and the mount is reachable unauthenticated. Mounted
    # Grape APIs are unaffected because they rebuild their own stack from the
    # inherited settings. Warn so this bypass isn't silent.
    def warn_unauthenticated_mounted_app
      return unless bare_rack_app?
      return unless inheritable_setting.namespace_inheritable[:auth]

      warn "Grape: #{config.app} is mounted under an API that declares authentication, but authentication " \
           'middleware does not wrap mounted Rack applications. Requests to this mount are not authenticated by Grape.'
    end

    def build_response_cookies
      return unless request.cookies?

      response_cookies do |name, value|
        cookie_value = value.is_a?(Hash) ? value : { value: }
        Rack::Utils.set_cookie_header! header, name, cookie_value
      end
    end

    def lint?
      inheritable_setting.namespace_inheritable[:lint] || Grape.config.lint
    end
  end
end
