# frozen_string_literal: true

module Grape
  module Validations
    module Types
      # A base class for classes which must identify a coercer to be used.
      # If the +strict+ argument is true, it won't coerce the given value
      # but check its type. More information there
      # https://dry-rb.org/gems/dry-types/main/built-in-types/
      class DryTypeCoercer
        class << self
          # Returns a collection coercer which corresponds to a given type.
          # Example:
          #
          #    collection_coercer_for(Array)
          #    #=> Grape::Validations::Types::ArrayCoercer
          def collection_coercer_for(type)
            case type
            when Array
              ArrayCoercer
            when Set
              SetCoercer
            else
              raise ArgumentError, "Unknown type: #{type}"
            end
          end

          # Returns an instance of a coercer for a given type
          def coercer_instance_for(type, strict = false)
            klass = type.instance_of?(Class) ? PrimitiveCoercer : collection_coercer_for(type)
            klass.new(type, strict)
          end
        end

        def initialize(type, strict = false)
          @type = type
          @strict = strict
          @cache_coercer = strict ? DryTypes::StrictCache : DryTypes::ParamsCache
        end

        # Coerces the given value to a type which was specified during
        # initialization as a type argument.
        #
        # @param val [Object]
        def call(val)
          return if val.nil?

          @coercer[val]
        rescue Dry::Types::CoercionError
          InvalidValue.new
        end

        protected

        attr_reader :type, :strict, :cache_coercer
      end
    end
  end
end
