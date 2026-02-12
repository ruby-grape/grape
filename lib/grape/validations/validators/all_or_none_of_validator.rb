# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class AllOrNoneOfValidator < MultipleParamsBase
        def initialize(attrs, options, required, scope, opts)
          super
          @exception_message = message(:all_or_none)
        end

        def validate_params!(params)
          keys = keys_in_common(params)
          return if keys.empty? || keys.length == all_keys.length

          raise Grape::Exceptions::Validation.new(params: all_keys, message: @exception_message)
        end
      end
    end
  end
end
