module Grape
  module Validations
    class MutualExclusionValidator < Validator
      attr_reader :params

      def validate!(params)
        @params = params
        if two_or_more_exclusive_params_are_present
          raise Grape::Exceptions::Validation, params: keys_in_common, message_key: :mutual_exclusion
        end
        params
      end

      private

      def two_or_more_exclusive_params_are_present
        keys_in_common.length > 1
      end

      def keys_in_common
        (attrs.map(&:to_s) & params.stringify_keys.keys).map(&:to_s)
      end
    end
  end
end
