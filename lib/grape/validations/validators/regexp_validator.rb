# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class RegexpValidator < Base
        def initialize(attrs, options, required, scope, opts)
          super
          @value = option_value
          @exception_message = message(:regexp)
        end

        def validate_param!(attr_name, params)
          return unless hash_like?(params) && params.key?(attr_name)

          return if Array.wrap(params[attr_name]).all? { |param| param.nil? || scrub(param.to_s).match?(@value) }

          raise Grape::Exceptions::Validation.new(params: @scope.full_name(attr_name), message: @exception_message)
        end
      end
    end
  end
end
