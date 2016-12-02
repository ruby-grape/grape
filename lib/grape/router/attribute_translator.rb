module Grape
  class Router
    # this could be an OpenStruct, but doesn't work in Ruby 2.3.0, see https://bugs.ruby-lang.org/issues/12251
    class AttributeTranslator
      def initialize(attributes = {})
        @attributes = attributes
      end

      def to_h
        @attributes
      end

      def method_missing(m, *args)
        if m[-1] == '='
          @attributes[m[0..-1]] = *args
        elsif m[-1] != '='
          @attributes[m]
        end
      end

      def respond_to_missing?(method_name, _include_private = false)
        if method_name[-1] == '='
          true
        else
          @attributes.key?(method_name)
        end
      end
    end
  end
end
