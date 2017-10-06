module Grape
  module Validations
    require 'grape/validations/validators/multiple_params_base'
    class AllOrNoneOfValidator < MultipleParamsBase
      def validate!(params)
        super
        if scope_requires_params && only_subset_present(params)
          raise Grape::Exceptions::Validation, params: all_keys, message: message(:all_or_none)
        end
        params
      end

      private

      def only_subset_present(params)
        scoped_params.any? do |resource_params|
          next unless scope_should_validate?(resource_params, params)

          !keys_in_common(resource_params).empty? && keys_in_common(resource_params).length < attrs.length
        end
      end
    end
  end
end
