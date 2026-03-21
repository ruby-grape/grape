# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class SameAsValidator < Base
        def initialize(attrs, options, required, scope, opts)
          super
          @value = option_value
        end

        def validate_param!(attr_name, params)
          return if params[attr_name] == params[@value]

          validation_error!(attr_name, message { translate(:same_as, parameter: @value) })
        end
      end
    end
  end
end
