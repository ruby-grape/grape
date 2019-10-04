module Grape
  module Validations
    require 'grape/validations/validators/multiple_params_base'
    class ExactlyOneOfValidator < MultipleParamsBase
      def validate_params!(params)
        if keys_in_common(params).length != 1
          raise Grape::Exceptions::Validation, params: all_keys, message: message(:exactly_one)
        end
      end
    end
  end
end
