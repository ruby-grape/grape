# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class AtLeastOneOfValidator < MultipleParamsBase
        default_message_key :at_least_one

        def validate_params!(params)
          known_keys = all_keys
          return if hash_like?(params) && known_keys.intersect?(params.keys.map { |attr| @scope.full_name(attr) })

          validation_error!(known_keys)
        end
      end
    end
  end
end
