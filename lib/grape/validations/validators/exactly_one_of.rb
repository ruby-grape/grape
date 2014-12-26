module Grape
  module Validations
    require 'grape/validations/validators/mutual_exclusion'
    class ExactlyOneOfValidator < MutualExclusionValidator
      def validate!(params)
        super
        if scope_requires_params && none_of_restricted_params_is_present
          fail Grape::Exceptions::Validation, params: all_keys, message_key: :exactly_one
        end
        params
      end

      private

      def none_of_restricted_params_is_present
        scoped_params.any? { |resource_params| keys_in_common(resource_params).empty? }
      end
    end
  end
end
