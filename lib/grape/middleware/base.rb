# frozen_string_literal: true

module Grape
  module Middleware
    class Base
      include Grape::DSL::Headers

      attr_reader :app, :env, :options

      # @param [Rack Application] app The standard argument for a Rack middleware.
      # @param [Hash] options Options forwarded to the subclass. When the
      #   subclass declares an `Options` Data class (recommended; see
      #   `Grape::Middleware::OptionsCompat`), the kwargs are routed through
      #   it. Otherwise they are deep-merged with the subclass's
      #   `DEFAULT_OPTIONS` Hash (legacy path) and frozen.
      def initialize(app, **options)
        @app = app
        @options = build_options(options)
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

      def build_options(options)
        return self.class::Options.new(**options) if self.class.const_defined?(:Options, false)

        merge_default_options(options).freeze
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
