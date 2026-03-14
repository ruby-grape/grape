# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class MutuallyExclusiveValidator < MultipleParamsBase
        def initialize(attrs, options, required, scope, opts)
          super
          @exception_message = message(:mutual_exclusion)
        end

        def validate_params!(params)
          keys = keys_in_common(params)
          return if keys.length <= 1

          raise Grape::Exceptions::Validation.new(params: keys, message: @exception_message)
        end
      end
    end
  end
end
