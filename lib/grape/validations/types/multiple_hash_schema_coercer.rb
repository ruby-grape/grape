# frozen_string_literal: true

module Grape
  module Validations
    module Types
      # This class handles coercion and validation for parameters declared
      # with multiple Hash schema variants using the +:types+ option with
      # HashSchema instances.
      #
      # It will validate the parameter value against each schema in order
      # and return the value if any schema passes validation.
      class MultipleHashSchemaCoercer
        attr_reader :schemas

        # Construct a new coercer for multiple Hash schemas.
        #
        # @param schemas [Array<HashSchema>] list of hash schemas
        def initialize(schemas)
          @schemas = schemas
        end

        # Validates the given Hash value against each schema.
        # Note: Actual validation happens in the validator, this just
        # ensures the value is a Hash.
        #
        # @param val [Hash] value to be validated
        # @return [Hash,InvalidValue] the validated hash, or an instance
        #   of {InvalidValue} if the value is not a Hash.
        def call(val)
          return InvalidValue.new unless val.is_a?(Hash)

          # Return the hash - actual schema validation will happen
          # in MultipleHashSchemaValidator
          val
        end
      end
    end
  end
end
