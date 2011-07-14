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
      
      def default_options; {} end
      
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
        Rack::Request.new(self.env)
      end
      
      def response
        Rack::Response.new(@app_response)
      end


      module Formats

        CONTENT_TYPES = {
          :xml => 'application/xml',
          :json => 'application/json',
          :atom => 'application/atom+xml',
          :rss => 'application/rss+xml',
          :txt => 'text/plain'
        }
        FORMATTERS = {
          :json => :encode_json,
          :txt => :encode_txt,
        }

        def formatters
          FORMATTERS.merge(options[:formatters] || {})
        end

        def content_types
          CONTENT_TYPES.merge(options[:content_types] || {})
        end

        def content_type
          content_types[options[:format]] || 'text/html'
        end

        def mime_types
          content_types.invert
        end

        def formatter_for(api_format)
          spec = formatters[api_format]
          case spec
          when nil
            lambda { |obj| obj }
          when Symbol
            method(spec)
          else
            spec
          end
        end

      end

    end
  end
end
