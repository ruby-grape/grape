# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class SameAsValidator < Base
        def initialize(attrs, options, required, scope, opts)
          super
          # Names a param: a String becomes a Symbol, as in a declaration (see
          # Grape::DSL::Parameters#param_names).
          @value = option_value.is_a?(String) ? option_value.to_sym : option_value
        end

        def validate_param!(attr_name, params)
          return unless hash_like?(params)
          return if params[attr_name] == params[@value]

          validation_error!(attr_name, message { translate(:same_as, parameter: @value) })
        end
      end
    end
  end
end
