module Grape
  module Validations
    require 'grape/validations/validators/mutual_exclusion'
    class ExactlyOneOfValidator < MutualExclusionValidator
      def validate!(params)
        super
        if scope_requires_params && none_of_restricted_params_is_present
          raise Grape::Exceptions::Validation, params: all_keys, message: message(:exactly_one)
        end
        params
      end

      def message(default_key = nil)
        options = instance_variable_get(:@option)
        if options_key?(:message)
          (options_key?(default_key, options[:message]) ? options[:message][default_key] : options[:message])
        else
          default_key
        end
      end

      private

      def none_of_restricted_params_is_present
        scoped_params.any? { |resource_params| keys_in_common(resource_params).empty? }
      end
    end
  end
end
