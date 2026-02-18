# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class ExceptValuesValidator < Base
        def initialize(attrs, options, required, scope, opts)
          super
          except = option_value
          raise ArgumentError, 'except_values Proc must have arity of zero' if except.is_a?(Proc) && !except.arity.zero?

          # important! lazy call at runtime
          @excepts_call = except.is_a?(Proc) ? except : -> { except }
          @exception_message = message(:except_values)
        end

        def validate_param!(attr_name, params)
          return unless hash_like?(params) && params.key?(attr_name)

          excepts = @excepts_call.call
          return if excepts.nil?

          param_array = params[attr_name].nil? ? [nil] : Array.wrap(params[attr_name])
          return if param_array.none? { |param| excepts.include?(param) }

          raise Grape::Exceptions::Validation.new(params: @scope.full_name(attr_name), message: @exception_message)
        end
      end
    end
  end
end
