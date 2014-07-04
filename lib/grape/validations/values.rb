module Grape
  module Validations
    class ValuesValidator < Validator
      def initialize(attrs, options, required, scope)
        @values = options
        @required = required
        super
      end

      def validate_param!(attr_name, params)
        if (params[attr_name] || required_for_root_scope?) && !(@values.is_a?(Proc) ? @values.call : @values).include?(params[attr_name])
          raise Grape::Exceptions::Validation, param: @scope.full_name(attr_name), message_key: :values
        end
      end

      private

      def required_for_root_scope?
        @required && @scope.root?
      end
    end
  end
end
