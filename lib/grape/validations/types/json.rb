require 'json'

module Grape
  module Validations
    module Types
      # +Virtus::Attribute+ implementation that handles coercion
      # and type checking for parameters that are complex types
      # given as JSON-encoded strings. It accepts both JSON objects
      # and arrays of objects, and will coerce the input to a +Hash+
      # or +Array+ object respectively. In either case the Grape
      # validation system will apply nested validation rules to
      # all returned objects.
      class Json < Virtus::Attribute
        # Coerce the input into a JSON-like data structure.
        #
        # @param input [String] a JSON-encoded parameter value
        # @return [Hash,Array<Hash>,nil]
        def coerce(input)
          # Allow nulls and blank strings
          return if input.nil? || input =~ /^\s*$/
          JSON.parse(input, symbolize_names: true)
        end

        # Checks that the input was parsed successfully
        # and isn't something odd such as an array of primitives.
        #
        # @param value [Object] result of {#coerce}
        # @return [true,false]
        def value_coerced?(value)
          value.is_a?(::Hash) || coerced_collection?(value)
        end

        protected

        # Is the value an array of JSON-like objects?
        #
        # @param value [Object] result of {#coerce}
        # @return [true,false]
        def coerced_collection?(value)
          value.is_a?(::Array) && value.all? { |i| i.is_a? ::Hash }
        end
      end

      # Specialization of the {Json} attribute that is guaranteed
      # to return an array of objects. Accepts both JSON-encoded
      # objects and arrays of objects, but wraps single objects
      # in an Array.
      class JsonArray < Json
        # See {Json#coerce}. Wraps single objects in an array.
        #
        # @param input [String] JSON-encoded parameter value
        # @return [Array<Hash>]
        def coerce(input)
          json = super
          Array.wrap(json) unless json.nil?
        end

        # See {Json#coerced_collection?}
        def value_coerced?(value)
          coerced_collection? value
        end
      end
    end
  end
end
