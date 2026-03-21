# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class RegexpValidator < Base
        default_message_key :regexp

        def initialize(attrs, options, required, scope, opts)
          super
          @value = option_value
        end

        def validate_param!(attr_name, params)
          return unless hash_like?(params) && params.key?(attr_name)

          return if Array.wrap(params[attr_name]).all? { |param| param.nil? || scrub(param.to_s).match?(@value) }

          validation_error!(attr_name)
        end
      end
    end
  end
end
