# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class PresenceValidator < Base
        def initialize(attrs, options, required, scope, opts)
          super
          @exception_message = message(:presence)
        end

        def validate_param!(attr_name, params)
          return if hash_like?(params) && params.key?(attr_name)

          validation_error!(attr_name)
        end
      end
    end
  end
end
