# frozen_string_literal: true

module Grape
  module Validations
    module Types
      # A base class for classes which must identify a coercer to be used.
      # If the +strict+ argument is true, it won't coerce the given value
      # but check its type. More information there
      # https://dry-rb.org/gems/dry-types/main/built-in-types/
      class DryTypeCoercer
        extend Grape::Util::FreezeOnNew

        class << self
          # Returns a collection coercer which corresponds to a given type.
          # Example:
          #
          #    collection_coercer_for(Array)
          #    #=> Grape::Validations::Types::ArrayCoercer
          def collection_coercer_for(type)
            return ArrayCoercer if type.is_a?(Array)
            return SetCoercer if type.is_a?(Set)

            raise ArgumentError, "unknown type: `#{type}`"
          end

          # Returns an instance of a coercer for a given type
          def coercer_instance_for(type, strict: false)
            klass = type.instance_of?(Class) ? PrimitiveCoercer : collection_coercer_for(type)
            klass.new(type, strict:)
          end
        end

        def initialize(type, strict: false)
          @type = type
          @strict = strict
          @cache_coercer = strict ? DryTypes::StrictCache : DryTypes::ParamsCache
        end

        # Coerces the given value to a type which was specified during
        # initialization as a type argument.
        #
        # Given a block, dry-types reports a value it cannot coerce by calling
        # the block instead of raising. Raising is what cost: its CoercionError
        # is re-raised with the backtrace of the error underneath, and building
        # that backtrace as strings at request depth took about 25 µs for every
        # rejected value -- every `types: [Integer, String]` param given a
        # string, every 400 for a mistyped value.
        #
        # Every coercion dry-types runs takes that block, so none of them
        # raises a CoercionError here. Anything that raises something else --
        # +Kernel#String+, which +Coercible::String+ is built from, ignores the
        # block and raises TypeError -- is answered by
        # +CoerceValidator#coerce_value+, which rescues StandardError with the
        # same InvalidValue.
        #
        # @param val [Object]
        def call(val)
          return if val.nil?

          @coercer.call(val) { InvalidValue.new }
        end

        protected

        attr_reader :type, :strict, :cache_coercer
      end
    end
  end
end
