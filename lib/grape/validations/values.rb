module Grape
  module Validations
    class ValuesValidator < Validator
      def initialize(attrs, options, required, scope)
        @values = (options.is_a?(Proc) ? options.call : options)
        @required = required
        super
      end

      def validate_param!(attr_name, params)
        if (params[attr_name] || @required) && !@values.include?(params[attr_name])
          raise Grape::Exceptions::Validation, param: @scope.full_name(attr_name), message_key: :values
        end
      end
    end
  end
end
