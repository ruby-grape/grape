module Grape
  module Middleware
    class Base
      attr_reader :app, :env, :options
      TEXT_HTML = 'text/html'.freeze

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
      def before
      end

      # @abstract
      # Called after the application is called in the middleware lifecycle.
      # @return [Response, nil] a Rack SPEC response or nil to call the application afterwards.
      def after
      end

      def response
        return @app_response if @app_response.is_a?(Rack::Response)
        Rack::Response.new(@app_response[2], @app_response[0], @app_response[1])
      end

      def content_type_for(format)
        HashWithIndifferentAccess.new(content_types)[format]
      end

      def content_types
        ContentTypes.content_types_for(options[:content_types])
      end

      def content_type
        content_type_for(env[Grape::Env::API_FORMAT] || options[:format]) || TEXT_HTML
      end

      def mime_types
        types_without_params = {}
        content_types.each_pair do |k, v|
          types_without_params[v.split(';').first] = k
        end
        types_without_params
      end
    end
  end
end
