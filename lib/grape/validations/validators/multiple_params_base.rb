# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class MultipleParamsBase < Base
        def validate!(params)
          attributes = MultipleAttributesIterator.new(self, @scope, params)
          array_errors = []

          attributes.each do |resource_params|
            validate_params!(resource_params)
          rescue Grape::Exceptions::Validation => e
            array_errors << e
          end

          raise Grape::Exceptions::ValidationArrayErrors.new(array_errors) if array_errors.any?
        end

        private

        def keys_in_common(resource_params)
          return [] unless resource_params.is_a?(Hash)

          all_keys & resource_params.keys.map! { |attr| @scope.full_name(attr) }
        end

        def all_keys
          attrs.map { |attr| @scope.full_name(attr) }
        end
      end
    end
  end
end
