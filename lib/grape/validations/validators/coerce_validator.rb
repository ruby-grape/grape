# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class CoerceValidator < Base
        default_message_key :coerce

        def initialize(attrs, options, required, scope, opts)
          super

          @exception_message = options.message if options.message

          type = options.type
          @converter =
            if type.is_a?(Grape::Validations::Types::VariantCollectionCoercer)
              type
            else
              Types.build_coercer(type, method: options.coerce_method)
            end
        end

        # The attribute is read once and held: +coerce_value+ only ever sees the
        # value, never the Hash, so the two further reads the identity check
        # used to make came back with the same object -- through a
        # HashWithIndifferentAccess key conversion each time, for every coerced
        # attribute of every request.
        def validate_param!(attr_name, params)
          return unless hash_like?(params)

          value = params[attr_name]
          # Left out rather than sent as null, which reads the same. Only a
          # +nil+ is looked up, so a param that was sent spares the Hash the
          # lookup (see #validates_missing?).
          return if value.nil? && !params.key?(attr_name)

          new_value = coerce_value(value)

          invalid!(attr_name, new_value) if new_value.is_a?(Types::InvalidValue)

          # Don't assign a value if it is identical. It fixes a problem with Hashie::Mash
          # which loses wrappers for hashes and arrays after reassigning values
          #
          #     h = Hashie::Mash.new(list: [1, 2, 3, 4])
          #     => #<Hashie::Mash list=#<Hashie::Array [1, 2, 3, 4]>>
          #     list = h.list
          #     h[:list] = list
          #     h
          #     => #<Hashie::Mash list=[1, 2, 3, 4]>
          return if value.instance_of?(new_value.class) && value == new_value

          params[attr_name] = new_value
        end

        private

        # Asked about every required attribute, unlike the other validators,
        # as it reads each one anyway: every typed param has a coercion, and
        # on the elements of an Array the key lookup cost a nested body of 20
        # items some 5%. A param left out is still never coerced. An optional
        # one is asked about only when it was sent, as a request leaves most
        # of those out, and reading one that is not there costs a
        # HashWithIndifferentAccess more than asking whether it holds it.
        def validates_missing?
          required?
        end

        def invalid!(attr_name, invalid_value)
          validation_error!(attr_name, invalid_value.message || exception_message)
        end

        # Calls the converter built at definition time.
        # Custom coercers may raise; any StandardError is treated as an invalid value.
        def coerce_value(val)
          @converter.call(val)
        rescue StandardError
          Types::InvalidValue.new
        end
      end
    end
  end
end
