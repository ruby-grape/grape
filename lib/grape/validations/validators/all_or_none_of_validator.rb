# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class AllOrNoneOfValidator < MultipleParamsBase
        default_message_key :all_or_none

        def validate_params!(params)
          known_keys = all_keys
          keys = keys_in_common(params, known_keys)
          return if keys.empty? || keys.length == @attrs.length

          validation_error!(known_keys)
        end
      end
    end
  end
end
