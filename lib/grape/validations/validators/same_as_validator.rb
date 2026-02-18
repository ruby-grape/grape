# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class SameAsValidator < Base
        def initialize(attrs, options, required, scope, opts)
          super
          @value = option_value
          @exception_message = message { { key: :same_as, parameter: @value }.freeze }
        end

        def validate_param!(attr_name, params)
          return if params[attr_name] == params[@value]

          raise Grape::Exceptions::Validation.new(params: @scope.full_name(attr_name), message: @exception_message)
        end
      end
    end
  end
end
