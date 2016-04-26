module Grape
  module Validations
    require 'grape/validations/validators/multiple_params_base'
    class MutualExclusionValidator < MultipleParamsBase
      attr_reader :processing_keys_in_common

      def validate!(params)
        super
        if two_or_more_exclusive_params_are_present
          raise Grape::Exceptions::Validation, params: processing_keys_in_common, message: message(:mutual_exclusion)
        end
        params
      end

      private

      def two_or_more_exclusive_params_are_present
        scoped_params.any? do |resource_params|
          @processing_keys_in_common = keys_in_common(resource_params)
          @processing_keys_in_common.length > 1
        end
      end
    end
  end
end
