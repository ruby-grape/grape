# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class AllowBlankValidator < Base
        def initialize(attrs, options, required, scope, opts)
          super

          @value = option_value
          @exception_message = message(:blank)
        end

        def validate_param!(attr_name, params)
          return if @value || !hash_like?(params)

          value = scrub(params[attr_name])
          return if value == false || value.present?

          validation_error!(attr_name)
        end
      end
    end
  end
end
