# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class ValuesValidator < Base
        default_message_key :values

        # The arities of a Proc that can be called with one value: one
        # parameter, or at most one required before optional ones or a splat.
        PREDICATE_ARITIES = [1, -1, -2].freeze

        def initialize(attrs, options, required, scope, opts)
          super
          values = option_value

          # Zero-arity procs return a collection per-request (e.g. DB-backed lists).
          # Non-zero-arity procs are per-element predicates, called directly at validation time.
          # Anything else is the collection itself, held as it came rather than
          # behind a lambda that would only hand it back.
          if values.is_a?(Proc)
            check_arity!(values.arity)
            @values_call = values
            @values_is_predicate = !values.arity.zero?
          else
            @values = values
            @values_is_predicate = false
          end
        end

        def validate_param!(attr_name, params)
          val = scrub(params[attr_name])

          return if val.nil? && !required?
          return if blank_and_allowed?(val)
          return if check_values?(val, attr_name)

          validation_error!(attr_name)
        end

        private

        # Each param is validated on its own, so a predicate is called with one
        # value. One that needed more used to raise on every request, which was
        # rescued and answered as an invalid value, and a non-lambda Proc got
        # nil for the others: neither could ever see a second param.
        def check_arity!(arity)
          return if arity.zero? || PREDICATE_ARITIES.include?(arity)

          raise ArgumentError, "`values` takes a Proc with no argument, returning the allowed values, or with one, checking each value, not a Proc of arity #{arity}: " \
                               "it is called with one param's value at a time. To check params together, use a custom validator or a contract rule"
        end

        # +false+ is a value: AS's +blank?+ says otherwise.
        def blank_and_allowed?(val)
          val != false && val.blank? && allow_blank?
        end

        def check_values?(val, attr_name)
          param_array = val.nil? ? [nil] : Array.wrap(val)
          return predicate_holds?(param_array, attr_name) if @values_is_predicate

          values = @values_call ? @values_call.call : @values
          values.nil? || param_array.all? { |param| values.include?(param) }
        end

        def predicate_holds?(param_array, attr_name)
          param_array.all? { |param| @values_call.call(param) }
        rescue StandardError => e
          warn "Error '#{e}' raised while validating attribute '#{attr_name}'"
          false
        end
      end
    end
  end
end
