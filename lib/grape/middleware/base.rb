# frozen_string_literal: true

module Grape
  module Middleware
    class Base
      include Grape::DSL::Headers

      attr_reader :app, :env, :options

      # @param [Rack Application] app The standard argument for a Rack middleware.
      # @param [Hash] options A hash of options, simply stored for use by subclasses.
      def initialize(app, **options)
        @app = app
        @options = merge_default_options(options)
        @app_response = nil
      end

      def call(env)
        dup.call!(env).to_a
      end

      def call!(env)
        @env = env
        before
        begin
          @app_response = @app.call(@env)
        ensure
          begin
            after_response = after
          rescue StandardError => e
            warn "caught error of type #{e.class} in after callback inside #{self.class.name} : #{e.message}"
            raise e
          end
        end

        response = after_response || @app_response
        merge_headers response
        response
      end

      # @abstract
      # Called before the application is called in the middleware lifecycle.
      def before; end

      # @abstract
      # Called after the application is called in the middleware lifecycle.
      # @return [Response, nil] a Rack SPEC response or nil to call the application afterwards.
      def after; end

      def rack_request
        @rack_request ||= Rack::Request.new(env)
      end

      def context
        env[Grape::Env::API_ENDPOINT]
      end

      def response
        return @app_response if @app_response.is_a?(Rack::Response)

        @app_response = Rack::Response[*@app_response]
      end

      def content_types
        @content_types ||= Grape::ContentTypes.content_types_for(options[:content_types])
      end

      def mime_types
        @mime_types ||= Grape::ContentTypes.mime_types_for(content_types)
      end

      def content_type_for(format)
        content_types_indifferent_access[format]
      end

      def content_type
        content_type_for(env[Grape::Env::API_FORMAT] || options[:format]) || 'text/html'
      end

      def query_params
        rack_request.GET
      rescue Rack::QueryParser::ParamsTooDeepError
        raise Grape::Exceptions::TooDeepParameters.new(Rack::Utils.param_depth_limit)
      rescue Rack::Utils::ParameterTypeError
        raise Grape::Exceptions::ConflictingTypes
      end

      private

      def merge_headers(response)
        return unless headers.is_a?(Hash)

        case response
        when Rack::Response then response.headers.merge!(headers)
        when Array          then response[1].merge!(headers)
        end
      end

      def content_types_indifferent_access
        @content_types_indifferent_access ||= content_types.with_indifferent_access
      end

      def merge_default_options(options)
        if respond_to?(:default_options)
          default_options.deep_merge(options)
        elsif self.class.const_defined?(:DEFAULT_OPTIONS)
          self.class::DEFAULT_OPTIONS.deep_merge(options)
        else
          options
        end
      end

      def try_scrub(obj)
        obj.respond_to?(:valid_encoding?) && !obj.valid_encoding? ? obj.scrub : obj
      end
    end
  end
end
