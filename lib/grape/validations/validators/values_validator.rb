# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class ValuesValidator < Base
        default_message_key :values

        def initialize(attrs, options, required, scope, opts)
          super
          values = option_value

          # Zero-arity procs return a collection per-request (e.g. DB-backed lists).
          # Non-zero-arity procs are per-element predicates, called directly at validation time.
          # Non-Proc values are wrapped in a zero-arity lambda for a uniform call interface.
          if values.is_a?(Proc)
            @values_call = values
            @values_is_predicate = !values.arity.zero?
          else
            @values_call = -> { values }
            @values_is_predicate = false
          end
        end

        def validate_param!(attr_name, params)
          return unless hash_like?(params)

          val = scrub(params[attr_name])

          return if val.nil? && !required_for_root_scope?
          return if val != false && val.blank? && @allow_blank
          return if check_values?(val, attr_name)

          validation_error!(attr_name)
        end

        private

        def check_values?(val, attr_name)
          param_array = val.nil? ? [nil] : Array.wrap(val)

          if @values_is_predicate
            begin
              param_array.all? { |param| @values_call.call(param) }
            rescue StandardError => e
              warn "Error '#{e}' raised while validating attribute '#{attr_name}'"
              false
            end
          else
            values = @values_call.call
            return true if values.nil?

            param_array.all? { |param| values.include?(param) }
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
