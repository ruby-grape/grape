# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class ExactlyOneOfValidator < MultipleParamsBase
        def validate_params!(params)
          keys = keys_in_common(params)
          return if keys.length == 1
          raise Grape::Exceptions::Validation.new(params: all_keys, message: message(:exactly_one)) if keys.empty?

          raise Grape::Exceptions::Validation.new(params: keys, message: message(:mutual_exclusion))
        end
      end
    end
  end
end
