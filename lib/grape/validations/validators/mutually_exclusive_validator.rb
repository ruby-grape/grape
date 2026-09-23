# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class MutuallyExclusiveValidator < MultipleParamsBase
        default_message_key :mutual_exclusion

        def validate_params!(params)
          present = present_attrs(params)
          return if present.length <= 1

          validation_error!(full_names(present))
        end
      end
    end
  end
end
