# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class MultipleParamsBase < Base
        def validate!(params)
          array_errors = nil

          @iterator.each(params) do |resource_params|
            validate_params!(resource_params)
          rescue Grape::Exceptions::Validation => e
            (array_errors ||= []) << e
          end

          raise Grape::Exceptions::ValidationArrayErrors.new(array_errors) if array_errors
        end

        private

        def iterator_class
          MultipleAttributesIterator
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
