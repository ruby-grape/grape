require 'grape/router/pattern'
require 'grape/router/attribute_translator'
require 'forwardable'
require 'pathname'

module Grape
  class Router
    class Route
      ROUTE_ATTRIBUTE_REGEXP = /route_([_a-zA-Z]\w*)/.freeze
      SOURCE_LOCATION_REGEXP = /^(.*?):(\d+?)(?::in `.+?')?$/.freeze
      TRANSLATION_ATTRIBUTES = [
        :prefix,
        :version,
        :namespace,
        :settings,
        :format,
        :description,
        :http_codes,
        :headers,
        :entity,
        :details,
        :requirements,
        :request_method
      ].freeze

      attr_accessor :pattern, :translator, :app, :index, :regexp

      alias_method :attributes, :translator

      extend Forwardable
      def_delegators :pattern, :path, :origin

      def self.translate(*attributes)
        AttributeTranslator.register(*attributes)
        def_delegators :@translator, *attributes
      end

      translate(*TRANSLATION_ATTRIBUTES)

      def method_missing(method_id, *arguments)
        match = ROUTE_ATTRIBUTE_REGEXP.match(method_id.to_s)
        if match
          method_name = match.captures.last.to_sym
          warn_route_methods(method_name, caller(1).shift)
          @options[method_name]
        else
          super
        end
      end

      def route_method
        warn_route_methods(:method, caller(1).shift, :request_method)
        request_method
      end

      def route_path
        warn_route_methods(:path, caller(1).shift)
        pattern.path
      end

      def initialize(method, pattern, options = {})
        @suffix     = options[:suffix]
        @options    = options.merge(method: method.to_s.upcase)
        @pattern    = Pattern.new(pattern, options)
        @translator = AttributeTranslator.new(options.merge(request_method: method.to_s.upcase))
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
          default = pattern.named_captures.keys.each_with_object({}) do |key, defaults|
            defaults[key] = ''
          end
          default.delete_if { |key, _| key == 'format' }.merge(translator.params)
        else
          parsed = pattern.params(input)
          parsed ? parsed.delete_if { |_, value| value.nil? }.symbolize_keys : {}
        end
      end

      private

      def warn_route_methods(name, location, expected = nil)
        path, line = *location.scan(SOURCE_LOCATION_REGEXP).first
        path = File.realpath(path) if Pathname.new(path).relative?
        expected ||= name
        warn <<-EOS
#{path}:#{line}: The route_xxx methods such as route_#{name} have been deprecated, please use #{expected}.
        EOS
      end
    end
  end
end
