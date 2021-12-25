# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class AtLeastOneOfValidator < MultipleParamsBase
        def validate_params!(params)
          return unless keys_in_common(params).empty?

          raise Grape::Exceptions::Validation.new(params: all_keys, message: message(:at_least_one))
        end
      end
    end
  end
end
