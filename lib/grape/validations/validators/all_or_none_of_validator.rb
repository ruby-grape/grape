# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class AllOrNoneOfValidator < MultipleParamsBase
        default_message_key :all_or_none

        def validate_params!(params)
          keys = keys_in_common(params)
          return if keys.empty? || keys.length == attrs.length

          validation_error!(all_keys)
        end
      end
    end
  end
end
