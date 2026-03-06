# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      # Validates that a parameter matches at least one of the provided Hash schemas.
      class MultipleHashSchemaValidator < Base
        def initialize(attrs, options, required, scope, opts)
          super
          @schemas = Array(options).select { |s| s.is_a?(Grape::Validations::Types::HashSchema) }
          @api = scope.instance_variable_get(:@api)
        end

        def validate_param!(attr_name, params)
          value = params[attr_name]
          return if value.nil? && !@required

          unless value.is_a?(Hash)
            raise Grape::Exceptions::Validation.new(
              params: [@scope.full_name(attr_name)],
              message: 'is invalid'
            )
          end

          # Try to validate against each schema and collect results
          results = []
          @schemas.each do |schema|
            result = schema.validate_hash(value, attr_name, @api, @scope)
            if result.valid?
              # Validation succeeded for this schema
              return
            end

            results << result
          end

          # None of the schemas matched - determine best error message
          raise_best_error(attr_name, results)
        end

        private

        def raise_best_error(attr_name, results)
          # Find the result with the highest score (closest match)
          best_result = results.max_by(&:score)

          # If we have a result with matched keys, it suggests user intent
          # Use specific errors from that schema
          if best_result.matched_keys.positive?
            # Collect all errors from the best matching schema
            if best_result.errors.length == 1
              # Single error - use original format
              error = best_result.errors.first
              param_path = build_param_path(attr_name, error[:path])

              raise Grape::Exceptions::Validation.new(
                params: [param_path],
                message: error[:message]
              )
            else
              # Multiple errors - combine them into a single message
              # Format: "field1 is missing, field2 is missing"
              error_messages = best_result.errors.map do |error|
                # Build the relative path from the attribute name
                if error[:path].empty?
                  "#{@scope.full_name(attr_name)} #{error[:message]}"
                else
                  path_suffix = "[#{error[:path].join('][')}]"
                  "#{@scope.full_name(attr_name)}#{path_suffix} #{error[:message]}"
                end
              end.join(', ')

              # Use a proc for the message to bypass the default formatting
              # which would add the param name prefix
              raise Grape::Exceptions::Validation.new(
                params: [@scope.full_name(attr_name)],
                message: -> { error_messages }
              )
            end
          else
            # No keys matched any schema - generic error
            raise Grape::Exceptions::Validation.new(
              params: [@scope.full_name(attr_name)],
              message: 'does not match any of the allowed schemas'
            )
          end
        end

        def build_param_path(attr_name, path)
          if path.empty?
            @scope.full_name(attr_name)
          else
            base = @scope.full_name(attr_name)
            "#{base}[#{path.join('][')}]"
          end
        end
      end
    end
  end
end
