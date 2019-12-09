# frozen_string_literal: true

require_relative 'dry_type_coercer'

module Grape
  module Validations
    module Types
      # Coerces elements in an array. It might be an array of strings or integers or
      # anything else.
      #
      # It could've been possible to use an +of+
      # method (https://dry-rb.org/gems/dry-types/1.2/array-with-member/)
      # provided by dry-types. Unfortunately, it doesn't work for Grape because of
      # behavior of Virtus which was used earlier, a `Grape::Validations::Types::PrimitiveCoercer`
      # maintains Virtus behavior in coercing.
      class ArrayCoercer < DryTypeCoercer
        def initialize(type, strict = false)
          super

          @coercer = scope::Array
          @elem_coercer = PrimitiveCoercer.new(type.first, strict)
        end

        def call(_val)
          collection = super

          return collection if collection.is_a?(InvalidValue)

          coerce_elements collection
        end

        protected

        def coerce_elements(collection)
          collection.each_with_index do |elem, index|
            return InvalidValue.new if reject?(elem)

            coerced_elem = @elem_coercer.call(elem)

            return coerced_elem if coerced_elem.is_a?(InvalidValue)

            collection[index] = coerced_elem
          end

          collection
        end

        # This method maintaine logic which was defined by Virtus for arrays.
        # Virtus doesn't allow nil in arrays.
        def reject?(val)
          val.nil?
        end
      end
    end
  end
end
