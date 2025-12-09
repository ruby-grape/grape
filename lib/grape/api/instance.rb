# frozen_string_literal: true

module Grape
  class API
    # The API Instance class, is the engine behind Grape::API. Each class that inherits
    # from this will represent a different API instance
    class Instance
      extend Grape::DSL::Settings
      extend Grape::DSL::Desc
      extend Grape::DSL::Validations
      extend Grape::DSL::Callbacks
      extend Grape::DSL::Logger
      extend Grape::DSL::Middleware
      extend Grape::DSL::RequestResponse
      extend Grape::DSL::Routing
      extend Grape::DSL::Helpers
      extend Grape::Middleware::Auth::DSL

      Boolean = Grape::API::Boolean

      class << self
        extend Forwardable

        attr_accessor :configuration

        def_delegators :@base, :to_s

        def base=(grape_api)
          @base = grape_api
          grape_api.instances << self
        end

        def base_instance?
          self == @base.base_instance
        end

        # A class-level lock to ensure the API is not compiled by multiple
        # threads simultaneously within the same process.
        LOCK = Mutex.new

        # Clears all defined routes, endpoints, etc., on this API.
        def reset!
          reset_endpoints!
          reset_routes!
          reset_validations!
        end

        # This is the interface point between Rack and Grape; it accepts a request
        # from Rack and ultimately returns an array of three values: the status,
        # the headers, and the body. See [the rack specification]
        # (http://www.rubydoc.info/github/rack/rack/master/file/SPEC) for more.
        def call(env)
          compile!
          @instance.call(env)
        end

        def compile!
          return if @instance

          LOCK.synchronize { @instance ||= new }
        end

        # see Grape::Router#recognize_path
        def recognize_path(path)
          compile!
          @instance.router.recognize_path(path)
        end

        # Wipe the compiled API so we can recompile after changes were made.
        def change!
          @instance = nil
        end

        protected

        def inherit_settings(other_settings)
          top_level_setting.inherit_from other_settings.point_in_time_copy

          # Propagate any inherited params down to our endpoints, and reset any
          # compiled routes.
          endpoints.each do |e|
            e.inherit_settings(top_level_setting.namespace_stackable)
            e.reset_routes!
          end

          reset_routes!
        end

        private

        def inherited(subclass)
          super
          subclass.reset!
          subclass.logger logger.clone
        end
      end

      attr_reader :router

      # Builds the routes from the defined endpoints, effectively compiling
      # this API into a usable form.
      def initialize
        @router = Router.new
        add_head_not_allowed_methods_and_options_methods
        self.class.endpoints.each do |endpoint|
          endpoint.mount_in(@router)
        end

        @router.compile!
        @router.freeze
      end

      # Handle a request. See Rack documentation for what `env` is.
      def call(env)
        status, headers, response = @router.call(env)
        unless cascade?
          headers = Grape::Util::Header.new.merge(headers)
          headers.delete('X-Cascade')
        end

        [status, headers, response]
      end

      # Some requests may return a HTTP 404 error if grape cannot find a matching
      # route. In this case, Grape::Router adds a X-Cascade header to the response
      # and sets it to 'pass', indicating to grape's parents they should keep
      # looking for a matching route on other resources.
      #
      # In some applications (e.g. mounting grape on rails), one might need to trap
      # errors from reaching upstream. This is effectivelly done by unsetting
      # X-Cascade. Default :cascade is true.
      def cascade?
        namespace_inheritable = self.class.inheritable_setting.namespace_inheritable
        return namespace_inheritable[:cascade] if namespace_inheritable.key?(:cascade)
        return namespace_inheritable[:version_options][:cascade] if namespace_inheritable[:version_options]&.key?(:cascade)

        true
      end

      reset!

      private

      # For every resource add a 'OPTIONS' route that returns an HTTP 204 response
      # with a list of HTTP methods that can be called. Also add a route that
      # will return an HTTP 405 response for any HTTP method that the resource
      # cannot handle.
      def add_head_not_allowed_methods_and_options_methods
        # The paths we collected are prepared (cf. Path#prepare), so they
        # contain already versioning information when using path versioning.
        all_routes = self.class.endpoints.flat_map(&:routes)

        # Disable versioning so adding a route won't prepend versioning
        # informations again.
        without_root_prefix_and_versioning { collect_route_config_per_pattern(all_routes) }
      end

      def collect_route_config_per_pattern(all_routes)
        routes_by_regexp = all_routes.group_by(&:pattern_regexp)
        namespace_inheritable = self.class.inheritable_setting.namespace_inheritable

        # Build the configuration based on the first endpoint and the collection of methods supported.
        routes_by_regexp.each_value do |routes|
          next if routes.any? { |route| route.request_method == '*' }

          last_route = routes.last # Most of the configuration is taken from the last endpoint
          allowed_methods = routes.map(&:request_method)
          allowed_methods |= [Rack::HEAD] if !namespace_inheritable[:do_not_route_head] && allowed_methods.include?(Rack::GET)

          allow_header = namespace_inheritable[:do_not_route_options] ? allowed_methods : [Rack::OPTIONS] | allowed_methods
          last_route.app.options[:options_route_enabled] = true unless namespace_inheritable[:do_not_route_options] || allowed_methods.include?(Rack::OPTIONS)

          greedy_route = Grape::Router::GreedyRoute.new(last_route.pattern, endpoint: last_route.app, allow_header: allow_header)
          @router.associate_routes(greedy_route)
        end
      end

      ROOT_PREFIX_VERSIONING_KEY = %i[version version_options root_prefix].freeze
      private_constant :ROOT_PREFIX_VERSIONING_KEY

      # Allows definition of endpoints that ignore the versioning configuration
      # used by the rest of your API.
      def without_root_prefix_and_versioning
        inheritable_setting = self.class.inheritable_setting
        deleted_values = inheritable_setting.namespace_inheritable.delete(*ROOT_PREFIX_VERSIONING_KEY)
        yield
      ensure
        ROOT_PREFIX_VERSIONING_KEY.each_with_index do |key, index|
          inheritable_setting.namespace_inheritable[key] = deleted_values[index]
        end
      end
    end
  end
end
