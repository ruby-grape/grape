# frozen_string_literal: true

module Grape
  module Validations
    module Types
      # This class will detect type classes that implement
      # a class-level +parse+ method. The method should accept one
      # +String+ argument and should return the value coerced to
      # the appropriate type. The method may raise an exception if
      # there are any problems parsing the string.
      #
      # Alternately an optional +method+ may be supplied (see the
      # +coerce_with+ option of {Grape::Dsl::Parameters#requires}).
      # This may be any class or object implementing +parse+ or +call+,
      # with the same contract as described above.
      #
      # Type Checking
      # -------------
      #
      # Calls to +coerced?+ will consult this class to check
      # that the coerced value produced above is in fact of the
      # expected type. By default this class performs a basic check
      # against the type supplied, but this behaviour will be
      # overridden if the class implements a class-level
      # +coerced?+ or +parsed?+ method. This method
      # will receive a single parameter that is the coerced value
      # and should return +true+ if the value meets type expectations.
      # Arbitrary assertions may be made here but the grape validation
      # system should be preferred.
      #
      # Alternately a proc or other object responding to +call+ may be
      # supplied in place of a type. This should implement the same
      # contract as +coerced?+, and must be supplied with a coercion
      # +method+.
      class CustomTypeCoercer
        TYPE_CHECK_METHODS = %i[coerced? parsed?].freeze
        COLLECTION_TYPES = [Array, Set].freeze
        private_constant :TYPE_CHECK_METHODS, :COLLECTION_TYPES

        # A new coercer for the given type specification
        # and coercion method.
        #
        # @param type [Class,#coerced?,#parsed?,#call?]
        #   specifier for the target type. See class docs.
        # @param method [#parse,#call]
        #   optional coercion method. See class docs.
        def initialize(type, method = nil)
          @method = build_coercion_method(type, method)
          @type_check = infer_type_check(type)
        end

        # Coerces the given value.
        #
        # @param value [String] value to be coerced, in grape
        #   this should always be a string.
        # @return [Object] the coerced result
        def call(val)
          coerced_val = @method.call(val)

          return coerced_val if coerced_val.is_a?(InvalidValue)
          return InvalidValue.new unless coerced?(coerced_val)

          coerced_val
        end

        def coerced?(val)
          val.nil? || @type_check.call(val)
        end

        private

        def build_coercion_method(type, method)
          coercion_method = infer_coercion_method(type, method)
          return hash_symbolizer(coercion_method) if type == Hash
          return collection_symbolizer(coercion_method) if COLLECTION_TYPES.include?(type)

          coercion_method
        end

        def infer_coercion_method(type, method)
          return type.method(:parse) unless method
          return method unless method.respond_to?(:parse)

          method.method(:parse)
        end

        def hash_symbolizer(method)
          ->(val) { method.call(val).deep_symbolize_keys }
        end

        def collection_symbolizer(method)
          ->(val) { method.call(val).map! { |item| symbolize_if_hash(item) } }
        end

        def symbolize_if_hash(item)
          item.is_a?(Hash) ? item.deep_symbolize_keys : item
        end

        def infer_type_check(type)
          method_name = TYPE_CHECK_METHODS.detect { |m| type.respond_to?(m) }
          return type.method(method_name) if method_name
          return type if type.respond_to?(:call)
          return enumerable_type_check(type) if type.is_a?(Enumerable)

          ->(value) { value.is_a? type }
        end

        def enumerable_type_check(type)
          ->(value) { value.is_a?(Enumerable) && value.all? { |val| recursive_type_check(type.first, val) } }
        end

        def recursive_type_check(type, value)
          return value.all? { |val| recursive_type_check(type.first, val) } if type.is_a?(Enumerable) && value.is_a?(Enumerable)

          !type.is_a?(Enumerable) && value.is_a?(type)
        end
      end
    end
  end
end
