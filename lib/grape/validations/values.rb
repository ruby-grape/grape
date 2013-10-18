module Grape
  module Validations
    class ValuesValidator < Validator
      def initialize(attrs, options, required, scope)
        @values = options
        super
      end

      def validate_param!(attr_name, params)
        if params[attr_name] && !@values.include?(params[attr_name])
          raise Grape::Exceptions::Validation, param: @scope.full_name(attr_name), message_key: :values
        end
      end
    end
  end
end
