module Grape
  module Validations
    class AtLeastOneOfValidator < Validator
      attr_reader :params

      def validate!(params)
        @params = params
        if no_exclusive_params_are_present
          raise Grape::Exceptions::Validation, params: attrs.map(&:to_s), message_key: :at_least_one
        end
        params
      end

      private

      def no_exclusive_params_are_present
        keys_in_common.length == 0
      end

      def keys_in_common
        (attrs.map(&:to_s) & params.stringify_keys.keys).map(&:to_s)
      end
    end
  end
end
