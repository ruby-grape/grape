# frozen_string_literal: true

module Grape
  class Router
    class Route < BaseRoute
      extend Forwardable

      FORWARD_MATCH_METHOD = ->(input, pattern) { input.start_with?(pattern.origin) }
      NON_FORWARD_MATCH_METHOD = ->(input, pattern) { pattern.match?(input) }

      attr_reader :app, :request_method

      def_delegators :pattern, :path, :origin

      def initialize(method, origin, path, options)
        @request_method = upcase_method(method)
        @pattern = Grape::Router::Pattern.new(origin, path, options)
        @match_function = options[:forward_match] ? FORWARD_MATCH_METHOD : NON_FORWARD_MATCH_METHOD
        super(options)
      end

      def convert_to_head_request!
        @request_method = Rack::HEAD
      end

      def exec(env)
        @app.call(env)
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
        return {} unless parsed

        parsed.compact.symbolize_keys
      end

      private

      def params_without_input
        @params_without_input ||= pattern.captures_default.merge(attributes.params)
      end

      def upcase_method(method)
        method_s = method.to_s
        Grape::HTTP_SUPPORTED_METHODS.detect { |m| m.casecmp(method_s).zero? } || method_s.upcase
      end
    end
  end
end
