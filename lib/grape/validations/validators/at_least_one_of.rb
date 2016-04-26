module Grape
  module Validations
    require 'grape/validations/validators/multiple_params_base'
    class AtLeastOneOfValidator < MultipleParamsBase
      def validate!(params)
        super
        if scope_requires_params && no_exclusive_params_are_present
          raise Grape::Exceptions::Validation, params: all_keys, message: message(:at_least_one)
        end
        params
      end

      private

      def no_exclusive_params_are_present
        scoped_params.any? { |resource_params| keys_in_common(resource_params).empty? }
      end
    end
  end
end
