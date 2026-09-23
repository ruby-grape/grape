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

        def present_attrs(resource_params)
          return [] unless hash_like?(resource_params)

          attrs.select { |attr| attr_present?(resource_params, attr) }.uniq
        end

        def any_attr_present?(resource_params)
          return false unless hash_like?(resource_params)

          attrs.any? { |attr| attr_present?(resource_params, attr) }
        end

        def attr_present?(params, attr)
          return true if params.key?(attr)

          alternate = attr.is_a?(Symbol) ? attr.to_s : attr.to_sym
          params.key?(alternate)
        end

        def full_names(attr_list)
          attr_list.map { |attr| scope.full_name(attr) }
        end

        def keys_in_common(resource_params, _known_keys = nil)
          full_names(present_attrs(resource_params))
        end

        def all_keys
          full_names(attrs)
        end
      end
    end
  end
end
