# frozen_string_literal: true

module Grape
  module DSL
    module Routing
      attr_reader :endpoints

      def given(conditional_option, &)
        return unless conditional_option

        mounted(&)
      end

      def mounted(&block)
        evaluate_as_instance_with_configuration(block, lazy: true)
      end

      def cascade(value = nil)
        return inheritable_setting.cascade_defined? ? inheritable_setting.cascade : true if value.nil?

        inheritable_setting.cascade = value
      end

      # Specify an API version.
      #
      # Called without arguments, returns the most recently declared version
      # (or +nil+). Called with one or more version strings, registers them
      # and stores a {Grape::DSL::VersionOptions} value object on the
      # inheritable settings; when given a block, the registration applies
      # within a nested namespace.
      #
      # @example API with legacy support.
      #   class MyAPI < Grape::API
      #     version 'v2'
      #
      #     get '/main' do
      #       {some: 'data'}
      #     end
      #
      #     version 'v1' do
      #       get '/main' do
      #         {legacy: 'data'}
      #       end
      #     end
      #   end
      #
      # @param args [Array<String, Symbol>] one or more version identifiers.
      # @param using [Symbol] versioning strategy — one of +:path+ (default),
      #   +:header+, +:param+, or +:accept_version_header+.
      # @param cascade [Boolean] forward to subsequent routes via the
      #   +X-Cascade+ header on version mismatch. Defaults to +true+.
      # @param parameter [String] name of the query/body parameter that
      #   carries the version when +using: :param+. Defaults to +'apiver'+.
      # @param strict [Boolean] reject requests that don't supply a usable
      #   version (header strategies). Defaults to +false+.
      # @param vendor [String, nil] vendor segment for the +:header+
      #   strategy (+application/vnd.<vendor>-<version>+); required when
      #   +using: :header+.
      # @yield optional block to scope routes under this version.
      # @return [String, nil] the most recently declared version.
      # @raise [Grape::Exceptions::MissingVendorOption] when +using: :header+
      #   is supplied without a +:vendor+.
      def version(*args, using: :path, cascade: true, parameter: 'apiver', strict: false, vendor: nil, &block)
        return @versions&.last if args.empty?

        raise Grape::Exceptions::MissingVendorOption.new if using == :header && vendor.nil?

        requested_versions = args.flatten.map(&:to_s)
        options = VersionOptions.new(using:, cascade:, parameter:, strict:, vendor:)

        @versions = versions | requested_versions

        if block
          within_namespace do
            inheritable_setting.version = requested_versions
            inheritable_setting.version_options = options
            instance_eval(&block)
          end
        else
          inheritable_setting.version = requested_versions
          inheritable_setting.version_options = options
        end

        @versions&.last
      end

      # Define a root URL prefix for your entire API.
      def prefix(prefix = nil)
        return inheritable_setting.root_prefix if prefix.nil?

        inheritable_setting.root_prefix = prefix.to_s
      end

      # Create a scope without affecting the URL.
      #
      # @param _name [Symbol] Purely placebo, just allows to name the scope to
      # make the code more readable.
      def scope(_name = nil, &block)
        within_namespace do
          nest(block)
        end
      end

      def build_with(build_with)
        inheritable_setting.build_params_with = build_with
      end

      # Do not route HEAD requests to GET requests automatically.
      def do_not_route_head!
        inheritable_setting.do_not_route_head!
      end

      # Do not automatically route OPTIONS.
      def do_not_route_options!
        inheritable_setting.do_not_route_options!
      end

      def lint!
        inheritable_setting.lint!
      end

      def do_not_document!
        inheritable_setting.do_not_document!
      end

      def mount(mounts, opts = {})
        mount_opts = opts
        if opts[:refresh_already_mounted]
          Grape.deprecator.warn('`refresh_already_mounted` is not a `mount` option and will be ignored in a future release.')
          drop_endpoints_mounted_for(mounts)
          # Dropped before the recursion below re-enters with the same options,
          # so a Grape API does not warn once per mount and once per instance.
          mount_opts = opts.except(:refresh_already_mounted)
        end

        normalize_mounts(mounts).each_pair do |app, path|
          if app.respond_to?(:mount_instance)
            mount({ app.mount_instance(configuration: mount_opts[:with] || {}) => path }, mount_opts)
            next
          end
          in_setting = inheritable_setting

          # Past the mount_instance branch above, a Grape app here is an already
          # instantiated Grape::API::Instance (vs. a bare Rack app).
          if app.is_a?(Grape::Mountable)
            mount_path = Grape::Util::PathNormalizer.call(path)
            app.top_level_setting.add_mount_path(mount_path)

            app.inherit_settings(inheritable_setting)

            in_setting = app.top_level_setting

            app.change!
            change!
          end

          endpoints << Grape::Endpoint.new(
            in_setting,
            http_methods: :any,
            path:,
            app:,
            anchor: false,
            api: self
          )
        end
      end

      # Defines a route that will be recognized
      # by the Grape API.
      #
      # @param methods [HTTP Verb] One or more HTTP verbs that are accepted by this route. Set to `:any` if you want any verb to be accepted.
      # @param paths [String] One or more strings representing the URL segment(s) for this route.
      # @param requirements [Hash] Regular-expression constraints for named path params; the route matches only when every requirement is satisfied.
      # @param anchor [Boolean] Whether the route is anchored to the whole path. Defaults to `true`; pass `false` for catch-all routes (e.g. `'/(*:path)'`).
      # @param route_options [Hash] Any additional custom options, carried through to `route.options`.
      #
      # @example Defining a basic route.
      #   class MyAPI < Grape::API
      #     route(:any, '/hello') do
      #       {hello: 'world'}
      #     end
      #   end
      def route(methods, paths = ['/'], requirements: nil, anchor: true, **route_options, &)
        http_methods = methods == :any ? '*' : methods
        endpoint_description = inheritable_setting.route_description

        # +params+, +requirements+ and +anchor+ each travel as their own endpoint
        # input; the route-options bag keeps the description's other keys
        # (+success+, +tags+, …) plus any custom options.
        params = prepare_params(endpoint_description[:params])
        all_route_options = endpoint_description.except(:params)
        all_route_options.deep_merge!(route_options) if route_options.present?

        new_endpoint = Grape::Endpoint.new(
          inheritable_setting,
          http_methods:,
          path: paths,
          api: self,
          params:,
          requirements:,
          anchor:,
          route_options: all_route_options,
          &
        )
        endpoints << new_endpoint unless endpoints.include?(new_endpoint)

        inheritable_setting.route_end
        reset_validations!
      end

      Grape::HTTP_SUPPORTED_METHODS.each do |supported_method|
        define_method supported_method.downcase do |path = '/', **options, &block|
          route(supported_method, path, **options, &block)
        end
      end

      # Declare a "namespace", which prefixes all subordinate routes with its
      # name. Any endpoints within a namespace, group, resource or segment,
      # etc., will share their parent context as well as any configuration
      # done in the namespace context.
      #
      # @example
      #
      #     namespace :foo do
      #       get 'bar' do
      #         # defines the endpoint: GET /foo/bar
      #       end
      #     end
      def namespace(space = nil, requirements: nil, **options, &block)
        return inheritable_setting.namespace_path unless space || block

        within_namespace do
          nest(block) do
            inheritable_setting.add_namespace(Grape::Namespace.new(space, requirements:, **options)) if space
          end
        end
      end

      alias group namespace
      alias resource namespace
      alias resources namespace
      alias segment namespace

      # An array of API routes.
      def routes
        @routes ||= endpoints.map(&:routes).flatten
      end

      # This method allows you to quickly define a parameter route segment
      # in your API.
      #
      # @param param [Symbol] The name of the parameter you wish to declare.
      # @option options [Regexp] You may supply a regular expression that the declared parameter must meet.
      def route_param(param, requirements: nil, type: nil, **, &)
        param_requirements = requirements.is_a?(Regexp) ? { param.to_sym => requirements } : requirements

        Grape::Validations::ParamsScope.new(api: self) do
          requires param, type: type
        end if type

        namespace(":#{param}", requirements: param_requirements, **, &)
      end

      # @return array of defined versions
      def versions
        @versions ||= []
      end

      private

      # Compose a route's params: the declared params (+params do … end+) deep-merged
      # with any documented alongside +desc ..., params:+ (+description_params+).
      def prepare_params(description_params)
        endpoint_params = inheritable_setting.params_documentation || {}
        return endpoint_params if description_params.blank?

        endpoint_params.deep_merge(description_params)
      end

      # Remove all defined routes.
      def reset_routes!
        endpoints.each(&:reset_routes!)
        @routes = nil
      end

      def reset_endpoints!
        @endpoints = []
      end

      # Re-mount +mounts+, replacing any endpoint already mounted for the same
      # base API rather than adding a second one. Called by
      # {Grape::API.refresh_mount_step} when a class-level method runs after the
      # API was mounted.
      def refresh_mounted_api(mounts, opts = {})
        drop_endpoints_mounted_for(mounts)
        mount(mounts, opts)
      end

      # A mounted Grape API is stored as the throwaway instance +mount+ built
      # for it, never as the class that was written, so endpoints are matched on
      # the base API both of them share.
      def drop_endpoints_mounted_for(mounts)
        normalize_mounts(mounts).each_key do |app|
          endpoints.delete_if { |endpoint| same_mounted_app?(endpoint.mounted_app, app) }
        end
      end

      # A bare app mounts at the root. The test is +Hash+ rather than
      # +respond_to?(:each_pair)+ because a Struct or an OpenStruct answers that
      # too, and neither can express an app => path mapping — their keys are
      # member names. Reading one as a mapping would silently mount nonsense
      # instead of mounting the app itself.
      def normalize_mounts(mounts)
        mounts.is_a?(Hash) ? mounts : { mounts => '/' }
      end

      # Two mounts refer to the same app when they share the same base Grape
      # API. +mount+ turns every mounted Grape API into a throwaway
      # +mount_instance+ (a fresh +Class.new+ per mount), so object identity
      # never holds across mounts; comparing the base is the real signal.
      # Plain Rack apps have no base and are mounted as-is, so they fall back
      # to object identity.
      def same_mounted_app?(mounted, app)
        return mounted.base.equal?(app.base) if mounted.respond_to?(:base) && app.respond_to?(:base)

        mounted.equal?(app)
      end

      # Execute first the provided block, then each of the
      # block passed in. Allows for simple 'before' setups
      # of settings stack pushes.
      def nest(*blocks, &block)
        blocks.compact!
        return instance_eval(&block) if blocks.empty?

        evaluate_as_instance_with_configuration(block) if block
        blocks.each { |b| evaluate_as_instance_with_configuration(b) }
        reset_validations!
      end

      def evaluate_as_instance_with_configuration(block, lazy: false)
        lazy_block = Grape::Util::Lazy::Block.new do |configuration|
          value_for_configuration = configuration
          self.configuration = value_for_configuration.evaluate if value_for_configuration.is_a?(Grape::Util::Lazy::Base)
          response = instance_eval(&block)
          self.configuration = value_for_configuration
          response
        end
        return lazy_block if @base && base_instance? && lazy

        lazy_block.evaluate_from(configuration)
      end
    end
  end
end
