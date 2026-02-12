# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class CoerceValidator < Base
        def initialize(attrs, options, required, scope, opts)
          super

          raw_type = @option[:type]
          type = hash_like?(raw_type) ? raw_type[:value] : raw_type
          @converter =
            if type.is_a?(Grape::Validations::Types::VariantCollectionCoercer)
              type
            else
              Types.build_coercer(type, method: @option[:method])
            end
          @exception_message = message(:coerce)
        end

        def validate_param!(attr_name, params)
          raise validation_exception(attr_name) unless hash_like?(params)

          new_value = coerce_value(params[attr_name])

          raise validation_exception(attr_name, new_value.message) if new_value.is_a?(Types::InvalidValue)

          # Don't assign a value if it is identical. It fixes a problem with Hashie::Mash
          # which looses wrappers for hashes and arrays after reassigning values
          #
          #     h = Hashie::Mash.new(list: [1, 2, 3, 4])
          #     => #<Hashie::Mash list=#<Hashie::Array [1, 2, 3, 4]>>
          #     list = h.list
          #     h[:list] = list
          #     h
          #     => #<Hashie::Mash list=[1, 2, 3, 4]>
          return if params[attr_name].instance_of?(new_value.class) && params[attr_name] == new_value

          params[attr_name] = new_value
        end

        private

        def coerce_value(val)
          @converter.call(val)
          # Some custom types might fail, so it should be treated as an invalid value
        rescue StandardError
          Types::InvalidValue.new
        end

        def validation_exception(attr_name, custom_msg = nil)
          Grape::Exceptions::Validation.new(
            params: @scope.full_name(attr_name),
            message: custom_msg || @exception_message
          )
        end
      end
    end
  end
end
