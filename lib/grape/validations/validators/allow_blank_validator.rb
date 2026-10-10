# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class AllowBlankValidator < Base
        default_message_key :blank

        def initialize(attrs, options, required, scope, opts)
          super
          @value = option_value
        end

        def validate_param!(attr_name, params)
          return if @value || !hash_like?(params)

          value = params[attr_name]
          return if value == false || !Grape::Util::Scrub.blank?(value)

          validation_error!(attr_name)
        end
      end
    end
  end
end
