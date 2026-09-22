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

        # Returns full names of the group attrs present on +resource_params+.
        #
        # Only the declared group attrs are inspected. The previous approach
        # mapped every request key through +scope.full_name+ then intersected
        # with the group — O(keys × nesting) per element, which dominated
        # large Array scopes with +mutually_exclusive+ / +exactly_one_of+ /
        # +all_or_none_of+.
        def keys_in_common(resource_params)
          return [] unless hash_like?(resource_params)

          attrs.filter_map do |attr|
            scope.full_name(attr) if resource_params.key?(attr)
          end
        end

        def all_keys
          attrs.map { |attr| scope.full_name(attr) }
        end
      end
    end
  end
end
