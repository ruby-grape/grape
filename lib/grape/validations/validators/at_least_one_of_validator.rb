# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class AtLeastOneOfValidator < MultipleParamsBase
        default_message_key :at_least_one

        def validate_params!(params)
          return unless present_attrs(params).empty?

          validation_error!(all_keys)
        end
      end
    end
  end
end
