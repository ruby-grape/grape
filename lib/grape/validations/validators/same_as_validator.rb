# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class SameAsValidator < Base
        def validate_param!(attr_name, params)
          confirmation = options_key?(:value) ? @option[:value] : @option
          return if params[attr_name] == params[confirmation]

          validation_error!(attr_name, build_message)
        end

        private

        def build_message
          if options_key?(:message)
            @option[:message]
          else
            translate(:same_as, parameter: option_value)
          end
        end
      end
    end
  end
end
