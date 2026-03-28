# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class PresenceValidator < Base
        default_message_key :presence

        def validate_param!(attr_name, params)
          return if hash_like?(params) && params.key?(attr_name)

          validation_error!(attr_name)
        end
      end
    end
  end
end
