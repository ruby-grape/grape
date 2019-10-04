require 'grape/validations/validators/multiple_params_base'

module Grape
  module Validations
    class MutualExclusionValidator < MultipleParamsBase
      def validate_params!(params)
        keys = keys_in_common(params)
        return if keys.length <= 1
        raise Grape::Exceptions::Validation, params: keys, message: message(:mutual_exclusion)
      end
    end
  end
end
