# frozen_string_literal: true

module Grape
  class Router
    class Route < BaseRoute
      extend Forwardable

      FORWARD_MATCH_METHOD = ->(input, pattern) { input.start_with?(pattern.origin) }
      NON_FORWARD_MATCH_METHOD = ->(input, pattern) { pattern.match?(input) }

      attr_reader :app, :request_method, :index

      def_delegators :@app, :call

      def initialize(endpoint, method, pattern, options, forward_match:, params: {}, **route_attributes)
        super(pattern, options, **route_attributes)
        @app = endpoint
        @request_method = upcase_method(method)
        @match_function = forward_match ? FORWARD_MATCH_METHOD : NON_FORWARD_MATCH_METHOD
        @declared_params = params
      end

      def to_head
        head = dup
        head.convert_to_head_request!
        head
      end

      def apply(app)
        @app = app
        self
      end

      def match?(input)
        return false if input.blank?

        @match_function.call(input, pattern)
      end

      # The route's declared params keyed by name — path captures plus any
      # declared body/query params, as their definitions. Used for documentation
      # (e.g. grape-swagger), not for extracting request values.
      def params
        @params ||= pattern.captures_default.merge(@declared_params)
      end

      # Extract param values from a matched request path. Used by the router.
      def params_for(input)
        parsed = pattern.params(input)
        return unless parsed

        parsed.compact.symbolize_keys
      end

      protected

      def convert_to_head_request!
        @request_method = Rack::HEAD
      end

      private

      def upcase_method(method)
        method_s = method.to_s
        Grape::HTTP_SUPPORTED_METHODS.detect { |m| m.casecmp(method_s).zero? } || method_s.upcase
      end
    end
  end
end
