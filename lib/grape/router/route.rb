# frozen_string_literal: true

module Grape
  class Router
    class Route < BaseRoute
      extend Forwardable

      FORWARD_MATCH_METHOD = ->(input, pattern) { input.start_with?(pattern.origin) }
      NON_FORWARD_MATCH_METHOD = ->(input, pattern) { pattern.match?(input) }

      attr_reader :app, :request_method, :index

      def_delegators :@app, :call

      def initialize(endpoint, method, pattern, options)
        super(pattern, options)
        @app = endpoint
        @request_method = upcase_method(method)
        @match_function = options[:forward_match] ? FORWARD_MATCH_METHOD : NON_FORWARD_MATCH_METHOD
      end

      def convert_to_head_request!
        @request_method = Rack::HEAD
      end

      def apply(app)
        @app = app
        self
      end

      def match?(input)
        return false if input.blank?

        @match_function.call(input, pattern)
      end

      def params(input = nil)
        return params_without_input if input.blank?

        parsed = pattern.params(input)
        return unless parsed

        parsed.compact.symbolize_keys
      end

      private

      def params_without_input
        @params_without_input ||= pattern.captures_default.merge(options[:params])
      end

      def upcase_method(method)
        method_s = method.to_s
        Grape::HTTP_SUPPORTED_METHODS.detect { |m| m.casecmp(method_s).zero? } || method_s.upcase
      end
    end
  end
end
