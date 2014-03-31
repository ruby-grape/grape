module Grape
  module Validations
    class DefaultValidator < Validator
      def initialize(attrs, options, required, scope)
        @default = options
        super
      end

      def validate_param!(attr_name, params)
        params[attr_name] = @default.is_a?(Proc) ? @default.call : @default unless params.has_key?(attr_name)
      end

      def validate!(params)
        attrs = AttributesIterator.new(self, @scope, params)
        parent_element = @scope.element
        attrs.each do |resource_params, attr_name|
          if resource_params[attr_name].nil?
            validate_param!(attr_name, resource_params)
            params[parent_element] = resource_params if parent_element && params[parent_element].nil?
          end
        end
      end
    end
  end
end
