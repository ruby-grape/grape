# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class AtLeastOneOfValidator < MultipleParamsBase
        def initialize(attrs, options, required, scope, opts)
          super
          @exception_message = message(:at_least_one)
        end

        def validate_params!(params)
          return if keys_in_common(params).any?

          raise Grape::Exceptions::Validation.new(params: all_keys, message: @exception_message)
        end
      end
    end
  end
end
