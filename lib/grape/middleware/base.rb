# frozen_string_literal: true

module Grape
  module Middleware
    class Base
      include Grape::DSL::Headers

      attr_reader :app, :env, :options, :config

      # @param [Rack Application] app The standard argument for a Rack middleware.
      # @param [Hash] options Options forwarded to the subclass. When the
      #   subclass declares an `Options` Data class, the kwargs are routed
      #   through it and exposed via {#config}; {#options} keeps returning a
      #   frozen Hash representation for back-compat with subclasses that read
      #   `options[:key]`. Otherwise the kwargs are deep-merged with the
      #   subclass's `DEFAULT_OPTIONS` Hash (legacy path) and frozen.
      def initialize(app, **options)
        @app = app
        if (config_class = options_data_class)
          @config = config_class.new(**options)
          @options = @config.to_h.freeze
        else
          @options = merge_default_options(options).freeze
        end
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

      def query_params
        rack_request.GET
      rescue *Grape::RACK_ERRORS
        raise Grape::Exceptions::RequestError
      end

      private

      def merge_headers(response)
        return if @header.blank?

        case response
        when Rack::Response then response.headers.merge!(@header)
        when Array          then response[1].merge!(@header)
        end
      end

      def merge_default_options(options)
        return default_options.deep_merge(options) if respond_to?(:default_options)

        default_options_constant&.deep_merge(options) || options
      end

      # self.class::Options honours middleware inheritance (e.g. Versioner::Path
      # → Versioner::Base) and, unlike const_defined?, never resolves a
      # top-level ::Options on Object. Absent an own/inherited Options class,
      # the lookup raises NameError and we fall back to the legacy path.
      def options_data_class
        self.class::Options
      rescue NameError
        nil
      end

      # Same idea as {#options_data_class} for the legacy DEFAULT_OPTIONS Hash.
      def default_options_constant
        self.class::DEFAULT_OPTIONS
      rescue NameError
        nil
      end

      def try_scrub(obj)
        obj.respond_to?(:valid_encoding?) && !obj.valid_encoding? ? obj.scrub : obj
      end
    end
  end
end
