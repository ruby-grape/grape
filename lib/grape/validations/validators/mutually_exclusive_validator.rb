# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class MutuallyExclusiveValidator < MultipleParamsBase
        default_message_key :mutual_exclusion

        def validate_params!(params)
          keys = keys_in_common(params)
          return if keys.length <= 1

          validation_error!(keys)
        end
      end
    end
  end
end
