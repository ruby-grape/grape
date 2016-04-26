module Grape
  module Validations
    require 'grape/validations/validators/multiple_params_base'
    class AllOrNoneOfValidator < MultipleParamsBase
      def validate!(params)
        super
        if scope_requires_params && only_subset_present
          raise Grape::Exceptions::Validation, params: all_keys, message: message(:all_or_none)
        end
        params
      end

      private

      def only_subset_present
        scoped_params.any? { |resource_params| !keys_in_common(resource_params).empty? && keys_in_common(resource_params).length < attrs.length }
      end
    end
  end
end
