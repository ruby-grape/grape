# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      # Validates that a Hash parameter matches at least one of a set of
      # variant schemas. Each variant is a list of pre-built validators
      # captured by evaluating the variant's block in a {Grape::Validations::OneofCollector}-backed
      # {ParamsScope}. At request time we try each variant in order against
      # its own copy of the value; the first variant that produces no errors
      # wins and its (possibly coerced) hash replaces the original.
      class OneofValidator < Base
        default_message_key :oneof

        def initialize(attrs, options, required, scope, opts)
          super
          @variants = Array(options)
        end

        def validate_param!(attr_name, params)
          return unless hash_like?(params)

          value = params[attr_name]
          return if value.nil? && !required?

          winning_candidate = nil
          @variants.each do |variant_validators|
            candidate = copy_containers(value)
            if variant_matches?(variant_validators, candidate)
              winning_candidate = candidate
              break
            end
          end

          return params[attr_name] = winning_candidate if winning_candidate

          validation_error!(attr_name)
        end

        private

        # Validators write into Hashes and Arrays, so a failed variant must not
        # share them with the next one. The leaves stay shared: +deep_dup+ reaches
        # a Tempfile by delegation and returns the File it wraps, which
        # Types::File then rejects.
        def copy_containers(value)
          return value.map { |element| copy_containers(element) } if value.is_a?(Array)
          return value unless value.is_a?(Hash)

          value.dup.transform_values! { |element| copy_containers(element) }
        end

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
