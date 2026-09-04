# frozen_string_literal: true

module Grape
  module Validations
    module Types
      # Coerces the given value to a type defined via a +type+ argument during
      # initialization. When +strict+ is true, it doesn't coerce a value but check
      # that it has the proper type.
      class PrimitiveCoercer < DryTypeCoercer
        # The input classes Virtus refused for a given declared type, keyed by
        # that type. Resolved once in #initialize rather than re-derived from
        # +type+ on every value: the answer only ever depends on the
        # declaration, and every coerced attribute of every request asks.
        REJECTED_INPUTS = { String => [Array, Hash].freeze, Hash => [String].freeze }.freeze

        def initialize(type, strict: false)
          super

          @coercer = cache_coercer[type]
          @rejected_inputs = REJECTED_INPUTS[type]
          @treat_empty_as_nil = type != String
        end

        def call(val)
          return InvalidValue.new if reject?(val)
          return if val.nil? || treat_as_nil?(val)

          super
        end

        protected

        attr_reader :type

        # This method maintains logic which was defined by Virtus. For example,
        # dry-types is ok to convert an array or a hash to a string, it is supported,
        # but Virtus wouldn't accept it. So, this method only exists to not introduce
        # breaking changes.
        def reject?(val)
          return false unless @rejected_inputs

          @rejected_inputs.any? { |klass| val.is_a?(klass) }
        end

        # Dry-Types treats an empty string as invalid. However, Grape considers an empty string as
        # absence of a value and coerces it into nil. See a discussion there
        # https://github.com/ruby-grape/grape/pull/2045
        def treat_as_nil?(val)
          @treat_empty_as_nil && val == ''
        end
      end
    end
  end
end
