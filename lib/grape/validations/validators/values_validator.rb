# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class ValuesValidator < Base
        def initialize(attrs, options, required, scope, opts)
          super
          values = option_value
          raise ArgumentError, 'values Proc must have arity of zero or one' if values.is_a?(Proc) && values.arity > 1

          # important! lazy call at runtime
          @values_call =
            if values.is_a?(Proc) && values.arity.zero?
              -> { values.call }
            else
              -> { values }
            end
          @exception_message = message(:values)
        end

        def validate_param!(attr_name, params)
          return unless hash_like?(params)

          val = scrub(params[attr_name])

          return if val.nil? && !required_for_root_scope?
          return if val != false && val.blank? && @allow_blank
          return if check_values?(val, attr_name)

          raise Grape::Exceptions::Validation.new(params: @scope.full_name(attr_name), message: @exception_message)
        end

        private

        def check_values?(val, attr_name)
          values = @values_call.call
          return true if values.nil?

          param_array = val.nil? ? [nil] : Array.wrap(val)
          return param_array.all? { |param| values.include?(param) } unless values.is_a?(Proc)

          begin
            param_array.all? { |param| values.call(param) }
          rescue StandardError => e
            warn "Error '#{e}' raised while validating attribute '#{attr_name}'"
            false
          end
        end

        def required_for_root_scope?
          return false unless @required

          scope = @scope
          scope = scope.parent while scope.lateral?

          scope.root?
        end
      end
    end
  end
end
