# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      # Validates that a Hash parameter matches at least one of a set of
      # variant schemas. Each variant is a list of pre-built validators
      # captured by evaluating the variant's block in a {Grape::Validations::OneofCollector}-backed
      # {ParamsScope}. At request time we try each variant in order against
      # a deep-dup of the value; the first variant that produces no errors
      # wins and its (possibly coerced) hash replaces the original.
      class OneofValidator < Base
        default_message_key :oneof

        def initialize(attrs, options, required, scope, opts)
          super
          @variants = Array(options)
        end

        def validate_param!(attr_name, params)
          value = params[attr_name]
          return if value.nil? && !@required

          winning_candidate = nil
          @variants.each do |variant_validators|
            candidate = value.deep_dup
            if variant_matches?(variant_validators, candidate)
              winning_candidate = candidate
              break
            end
          end

          return params[attr_name] = winning_candidate if winning_candidate

          validation_error!(attr_name)
        end

        private

        def variant_matches?(variant_validators, candidate)
          variant_validators.each { |v| v.validate!(candidate) }
          true
        rescue Grape::Exceptions::Validation, Grape::Exceptions::ValidationArrayErrors
          false
        end
      end
    end
  end
end
