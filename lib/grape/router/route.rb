# frozen_string_literal: true

require 'grape/router/pattern'
require 'grape/router/attribute_translator'
require 'forwardable'

module Grape
  class Router
    class Route
      FIXED_NAMED_CAPTURES = %w[format version].freeze

      attr_accessor :pattern, :translator, :app, :index, :options

      alias attributes translator

      extend Forwardable
      def_delegators :pattern, :path, :origin
      delegate Grape::Router::AttributeTranslator::ROUTE_ATTRIBUTES => :attributes

      def initialize(method, pattern, **options)
        method_s = method.to_s
        method_upcase = Grape::Http::Headers.find_supported_method(method_s) || method_s.upcase

        @options    = options.merge(method: method_upcase)
        @pattern    = Pattern.new(pattern, **options)
        @translator = AttributeTranslator.new(**options, request_method: method_upcase)
      end

      def exec(env)
        @app.call(env)
      end

      def apply(app)
        @app = app
        self
      end

      def match?(input)
        translator.respond_to?(:forward_match) && translator.forward_match ? input.start_with?(pattern.origin) : pattern.match?(input)
      end

      def params(input = nil)
        if input.nil?
          pattern.named_captures.keys.each_with_object(translator.params) do |(key), defaults|
            defaults[key] ||= '' unless FIXED_NAMED_CAPTURES.include?(key) || defaults.key?(key)
          end
        else
          parsed = pattern.params(input)
          parsed ? parsed.delete_if { |_, value| value.nil? }.symbolize_keys : {}
        end
      end
    end
  end
end
