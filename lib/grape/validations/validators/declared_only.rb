module Grape
  module Validations
    require 'grape/validations/validators/multiple_params_base'
    class DeclaredOnlyValidator < MultipleParamsBase
      attr_reader :extra_params

      def validate!(params)
        super
        if extra_params_are_present
          raise Grape::Exceptions::Validation, params: extra_params, message: message(:declared_only)
        end
        params
      end

      private

      def extra_params_are_present
        scoped_params.any? do |resource_params|
          @extra_params = undeclared_keys(resource_params)
          !@extra_params.empty?
        end
      end
    end
  end
end
