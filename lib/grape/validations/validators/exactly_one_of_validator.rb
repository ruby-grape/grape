# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class ExactlyOneOfValidator < MultipleParamsBase
        def initialize(attrs, options, required, scope, opts)
          super
          @exactly_one_exception_message = message(:exactly_one)
          @mutual_exclusion_exception_message = message(:mutual_exclusion)
        end

        def validate_params!(params)
          keys = keys_in_common(params)
          return if keys.length == 1

          validation_error!(all_keys, @exactly_one_exception_message) if keys.empty?
          validation_error!(keys, @mutual_exclusion_exception_message)
        end
      end
    end
  end
end
