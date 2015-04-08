module Grape
  module Validations
    class DefaultValidator < Base
      def initialize(attrs, options, required, scope)
        @default = options
        super
      end

      def validate_param!(attr_name, params)
        params[attr_name] = @default.is_a?(Proc) ? @default.call : @default unless params.key?(attr_name)
      end

      def validate!(params)
        return unless @scope.should_validate?(params)

        attrs = AttributesIterator.new(self, @scope, params)
        attrs.each do |resource_params, attr_name|
          if resource_params[attr_name].nil?
            validate_param!(attr_name, resource_params)
          end
        end
      end
    end
  end
end
