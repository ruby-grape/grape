module Grape
  module Middleware
    class Base
      attr_reader :app, :env, :options

      # @param [Rack Application] app The standard argument for a Rack middleware.
      # @param [Hash] options A hash of options, simply stored for use by subclasses.
      def initialize(app, options = {})
        @app = app
        @options = default_options.merge(options)
      end

      def default_options
        {}
      end

      def call(env)
        dup.call!(env)
      end

      def call!(env)
        @env = env
        before
        @app_response = @app.call(@env)
        after || @app_response
      end

      # @abstract
      # Called before the application is called in the middleware lifecycle.
      def before; end
      # @abstract
      # Called after the application is called in the middleware lifecycle.
      # @return [Response, nil] a Rack SPEC response or nil to call the application afterwards.
      def after; end

      def request
        Grape::Request.new(self.env)
      end

      def response
        Rack::Response.new(@app_response)
      end

      def content_type_for(format)
        HashWithIndifferentAccess.new(content_types)[format]
      end

      def content_types
        ContentTypes.content_types_for(options[:content_types])
      end

      def content_type
        content_type_for(env['api.format'] || options[:format]) || 'text/html'
      end

      def mime_types
        content_types.invert
      end

      private
      # Loop through the application endpoints, find routes that match the current path,
      # Collect the methods and return
      def allowed_methods_for_route
        methods = app.endpoints.map do |endpoint|
          # If the route has no namespace, it'll return '/', so we'll cover for that
          namespace = (endpoint.namespace == '/') ? '' : endpoint.namespace
          path = endpoint.options[:path].join
          method = endpoint.options[:method]

          method if (namespace + path) == env['PATH_INFO']
        end.compact

        methods << 'OPTIONS' unless app.settings[:do_not_route_options]
        methods << 'HEAD' unless app.settings[:do_not_route_head]

        methods
      end
    end
  end
end
