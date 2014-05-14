require 'grape/validations/validators/mutual_exclusion'

module Grape
  module Validations
    class ExactlyOneOfValidator < MutualExclusionValidator
      attr_reader :params

      def validate!(params)
        super
        if none_of_restricted_params_is_present
          raise Grape::Exceptions::Validation, param: "#{all_keys}", message_key: :exactly_one
        end
        params
      end

      private

      def none_of_restricted_params_is_present
        keys_in_common.length < 1
      end

      def all_keys
        attrs.map(&:to_sym)
      end
    end
  end
end
