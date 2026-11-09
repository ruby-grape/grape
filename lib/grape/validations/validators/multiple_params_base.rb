# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class MultipleParamsBase < Base
        # Group rules check their attributes together, so they cannot take
        # Base's per-attribute fast paths (@direct / @direct_elements).
        def validate!(params)
          validate_iterated!(params)
        end

        private

        def validate_element_attributes(element, array_errors)
          begin
            validate_params!(element)
          rescue Grape::Exceptions::Validation => e
            (array_errors ||= []) << e
          end
          array_errors
        end

        def keys_in_common(resource_params, known_keys = all_keys)
          return [] unless hash_like?(resource_params)

          known_keys & resource_params.keys.map! { |attr| scope.full_name(attr) }
        end

        def all_keys
          attrs.map { |attr| scope.full_name(attr) }
        end
      end
    end
  end
end
