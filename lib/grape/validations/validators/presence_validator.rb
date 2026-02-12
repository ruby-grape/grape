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

          raise Grape::Exceptions::Validation.new(params: @scope.full_name(attr_name), message: @exception_message)
        end
      end
    end
  end
end
