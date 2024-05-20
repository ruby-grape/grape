# frozen_string_literal: true

module Grape
  class Router
    class Route < BaseRoute
      extend Forwardable

      attr_reader :app, :request_method

      def_delegators :pattern, :path, :origin

      def initialize(method, pattern, **options)
        @request_method = upcase_method(method)
        @pattern = Grape::Router::Pattern.new(pattern, **options)
        super(**options)
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

        options[:forward_match] ? input.start_with?(pattern.origin) : pattern.match?(input)
      end

      def params(input = nil)
        return params_without_input if input.blank?

        parsed = pattern.params(input)
        return {} unless parsed

        parsed.compact.symbolize_keys
      end

      private

      def params_without_input
        pattern.captures_default.merge(attributes.params)
      end

      def upcase_method(method)
        method_s = method.to_s
        Grape::Http::Headers::SUPPORTED_METHODS.detect { |m| m.casecmp(method_s).zero? } || method_s.upcase
      end
    end
  end
end
