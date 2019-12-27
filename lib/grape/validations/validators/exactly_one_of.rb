# frozen_string_literal: true

require 'grape/validations/validators/multiple_params_base'

module Grape
  module Validations
    class ExactlyOneOfValidator < MultipleParamsBase
      def validate_params!(params)
        return if keys_in_common(params).length == 1
        raise Grape::Exceptions::Validation.new(params: all_keys, message: message(:exactly_one))
      end
    end
  end
end
