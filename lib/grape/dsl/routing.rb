# frozen_string_literal: true

module Grape
  module DSL
    module Routing
      attr_reader :endpoints

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
        within_namespace { nest(block) }
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
        validate_requirements!(requirements)

        http_methods = methods == :any ? '*' : methods
        endpoint_description = inheritable_setting.route_description

        # +params+, +requirements+ and +anchor+ each travel as their own endpoint
        # input; the route-options bag keeps the description's other keys
        # (+success+, +tags+, …) plus any custom options.
        new_endpoint = Grape::Endpoint.new(
          inheritable_setting,
          http_methods:,
          path: paths,
          api: self,
          params: prepare_params(endpoint_description[:params]),
          requirements:,
          anchor:,
          route_options: prepare_route_options(endpoint_description, route_options),
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
      def namespace(space = nil, requirements: nil, **, &block)
        return inheritable_setting.namespace_path unless space || block

        validate_requirements!(requirements)

        within_namespace do
          nest(block) do
            inheritable_setting.add_namespace(Grape::Namespace.new(space, requirements:, **)) if space
          end
        end
      end

      alias group namespace
      alias resource namespace
      alias resources namespace
      alias segment namespace

      # An array of API routes.
      def routes
        @routes ||= endpoints.flat_map(&:routes)
      end

      # This method allows you to quickly define a parameter route segment
      # in your API.
      #
      # @param param [Symbol] The name of the parameter you wish to declare.
      # @param requirements [Regexp, Class, Symbol] The constraint the parameter must meet.
      # @param type [Class] Declares the parameter with this type.
      def route_param(param, requirements: nil, type: nil, **, &)
        # The param is named here, so the constraint is its own: nest whatever
        # it is, not just a Regexp. A Hash would name the param twice, or key a
        # capture this namespace does not introduce, and belongs on +namespace+.
        raise ArgumentError, "route_param :`#{param}` constrains :`#{param}`; pass the constraint itself, or a Hash of requirements to the enclosing namespace" if requirements.respond_to?(:to_hash)

        param_requirements = requirements ? { param.to_sym => requirements } : requirements

        Grape::Validations::ParamsScope.new(api: self) do
          requires param, type: type
        end if type

        namespace(":#{param}", requirements: param_requirements, **, &)
      end

      private

      # Requirements are keyed by param name and merged across namespaces, so
      # anything else has nothing to attach to. Rejected here rather than at
      # the merge, which runs on the first request that builds the routes.
      def validate_requirements!(requirements)
        return if requirements.nil? || requirements.respond_to?(:to_hash)

        raise ArgumentError, "requirements must be a Hash of param name => constraint, got `#{requirements.class}`"
      end

      # Compose a route's params: the declared params (+params do … end+) deep-merged
      # with any documented alongside +desc ..., params:+ (+description_params+).
      def prepare_params(description_params)
        endpoint_params = inheritable_setting.params_documentation || {}
        return endpoint_params if description_params.blank?

        endpoint_params.deep_merge(description_params)
      end

      # The route's description (+desc+) less its +params+, with any custom
      # +route_options+ deep-merged over it.
      def prepare_route_options(description, route_options)
        description_options = description.except(:params)
        return description_options if route_options.empty?

        description_options.deep_merge!(route_options)
      end

      # Remove all defined routes.
      def reset_routes!
        endpoints.each(&:reset_routes!)
        @routes = nil
      end

      def reset_endpoints!
        @endpoints = []
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
    end
  end
end
