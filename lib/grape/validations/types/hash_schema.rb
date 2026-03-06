# frozen_string_literal: true

require 'ostruct'

module Grape
  module Validations
    module Types
      # Represents a Hash type with a specific schema defined by a block.
      # Used to support multiple Hash type variants in the types option.
      #
      # @example
      #   params do
      #     requires :value, types: [
      #       HashSchema.new { requires :fixed_price, type: Float },
      #       HashSchema.new { requires :time_unit, type: String; requires :rate, type: Float }
      #     ]
      #   end
      class HashSchema
        attr_reader :block

        # Result object containing validation details
        class ValidationResult
          attr_reader :errors, :matched_keys

          def initialize
            @errors = []
            @matched_keys = 0
            @success = true
          end

          def add_error(path, message)
            @errors << { path: path, message: message }
            @success = false
          end

          def increment_matched_keys
            @matched_keys += 1
          end

          def success?
            @success
          end

          # Calculate a score for this validation attempt
          # Higher score means closer to being valid
          def score
            # Prioritize schemas that matched more keys
            # Even if they failed validation, matching keys suggests intent
            (matched_keys * 100) - errors.length
          end

          def valid?
            @success
          end
        end

        # @param block [Proc] the validation block defining the Hash schema
        def initialize(&block)
          raise ArgumentError, 'HashSchema requires a block' unless block

          @block = block
          @schema_structure = nil
        end

        # Parses the schema block to extract the validation structure
        def parse_schema
          return @schema_structure if @schema_structure

          @schema_structure = { required: {}, optional: {} }

          # Create a mock scope that captures the schema structure
          parser = SchemaParser.new(@schema_structure)
          parser.instance_eval(&@block)

          @schema_structure
        end

        # Validates a hash value against this schema and returns detailed results
        # @param hash_value [Hash] the hash to validate
        # @param attr_name [Symbol] the parameter name
        # @param api [Grape::API] the API instance
        # @param parent_scope [ParamsScope] the parent scope
        # @return [ValidationResult] detailed validation result
        def validate_hash(hash_value, _attr_name, _api, _parent_scope)
          result = ValidationResult.new

          unless hash_value.is_a?(Hash)
            result.add_error([], 'must be a hash')
            return result
          end

          schema = parse_schema
          validate_structure(hash_value, schema, [], result)

          result
        end

        private

        def validate_structure(hash_value, schema, path, result)
          # Check all required fields
          schema[:required].each do |key, config|
            # Check if key exists (as symbol or string)
            actual_key = hash_value.key?(key) ? key : key.to_s
            value = hash_value[actual_key]

            if value.nil?
              result.add_error(path + [key], 'is missing')
              next
            end

            # Track that this key was present
            result.increment_matched_keys if path.empty?

            # If there's a type, validate and coerce it
            if config[:type]
              coerced_value = coerce_value(value, config[:type])
              if coerced_value.is_a?(Types::InvalidValue)
                result.add_error(path + [key], 'is invalid')
                next
              else
                # Update the hash with the coerced value
                hash_value[actual_key] = coerced_value
              end
            end

            # If there's a nested schema, validate recursively
            validate_structure(hash_value[actual_key], config[:schema], path + [key], result) if config[:schema]
          end

          # Validate optional fields if present
          schema[:optional].each do |key, config|
            actual_key = if hash_value.key?(key)
                           key
                         else
                           (hash_value.key?(key.to_s) ? key.to_s : nil)
                         end
            next if actual_key.nil?

            value = hash_value[actual_key]
            next if value.nil?

            # Track that this key was present
            result.increment_matched_keys if path.empty?

            # If there's a type, validate and coerce it
            if config[:type]
              coerced_value = coerce_value(value, config[:type])
              if coerced_value.is_a?(Types::InvalidValue)
                result.add_error(path + [key], 'is invalid')
                next
              else
                # Update the hash with the coerced value
                hash_value[actual_key] = coerced_value
              end
            end

            # If there's a nested schema, validate recursively
            validate_structure(hash_value[actual_key], config[:schema], path + [key], result) if config[:schema]
          end
        end

        def coerce_value(value, type)
          # If it's already the right type and Hash, no coercion needed
          return value if type == Hash && value.is_a?(Hash)

          # Try coercion
          coercer = Types.build_coercer(type)
          coercer.call(value)
        rescue StandardError
          Types::InvalidValue.new
        end

        # Helper class to parse schema definition blocks
        class SchemaParser
          def initialize(schema_structure)
            @schema_structure = schema_structure
          end

          def requires(key, type: nil, **_opts, &block)
            if block
              # Nested schema
              nested_schema = { required: {}, optional: {} }
              parser = SchemaParser.new(nested_schema)
              parser.instance_eval(&block)
              @schema_structure[:required][key] = { type: type, schema: nested_schema }
            else
              @schema_structure[:required][key] = { type: type }
            end
          end

          def optional(key, type: nil, **_opts, &block)
            if block
              # Nested schema
              nested_schema = { required: {}, optional: {} }
              parser = SchemaParser.new(nested_schema)
              parser.instance_eval(&block)
              @schema_structure[:optional][key] = { type: type, schema: nested_schema }
            else
              @schema_structure[:optional][key] = { type: type }
            end
          end

          def group(*args, &)
            # Ignore group for now
          end
        end
      end
    end
  end
end
