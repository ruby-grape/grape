# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class RegexpValidator < Base
        def validate_param!(attr_name, params)
          return unless params.respond_to?(:key) && params.key?(attr_name)

          value = options_key?(:value) ? @option[:value] : @option
          return if Array.wrap(params[attr_name]).all? { |param| param.nil? || scrub(param.to_s).match?(value) }

          raise Grape::Exceptions::Validation.new(params: [@scope.full_name(attr_name)], message: message(:regexp))
        end

        private

        def scrub(param)
          return param if param.valid_encoding?

          param.scrub
        end
      end
    end
  end
end
