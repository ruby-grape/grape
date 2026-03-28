# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class ExceptValuesValidator < Base
        default_message_key :except_values

        def initialize(attrs, options, required, scope, opts)
          super
          except = option_value
          raise ArgumentError, 'except_values Proc must have arity of zero (use values: with a one-arity predicate for per-element checks)' if except.is_a?(Proc) && !except.arity.zero?

          # Zero-arity procs (e.g. -> { User.pluck(:role) }) must be called per-request,
          # not at definition time, so they are wrapped in a lambda to defer execution.
          @excepts_call = except.is_a?(Proc) ? except : -> { except }
        end

        def validate_param!(attr_name, params)
          return unless hash_like?(params) && params.key?(attr_name)

          excepts = @excepts_call.call
          return if excepts.nil?

          param_array = params[attr_name].nil? ? [nil] : Array.wrap(params[attr_name])
          return if param_array.none? { |param| excepts.include?(param) }

          validation_error!(attr_name)
        end
      end
    end
  end
end
