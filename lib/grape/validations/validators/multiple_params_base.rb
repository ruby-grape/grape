# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class MultipleParamsBase < Base
        def initialize(attrs, options, required, scope, opts)
          super
          @group = @attrs.uniq.freeze
        end

        # Group rules check their attributes together, so they cannot take
        # Base's per-attribute fast paths (@direct / @direct_elements).
        def validate!(params)
          validate_iterated!(params)
        end

        private

        attr_reader :group

        def validate_element_attributes(element, array_errors)
          begin
            validate_params!(element)
          rescue Grape::Exceptions::Validation => e
            (array_errors ||= []) << e
          end
          array_errors
        end

        def present_attrs(params)
          return [] unless hash_like?(params)

          group.select { |name| params.key?(name) }
        end

        def full_names(names) = names.map { |name| scope.full_name(name) }

        def all_keys = full_names(group)
      end
    end
  end
end
