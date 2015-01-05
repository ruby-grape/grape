module Grape
  module Validations
    class DefaultValidator < Base
      def initialize(attrs, options, required, scope)
        @default = options
        super
      end

      def validate_param!(attr_name, params)
        unless params.key?(attr_name)
          params[attr_name] =
          if @default.is_a?(Proc)
            @default.call(*@default.parameters.map! { |param| param[1] }.map { |param| @context[param] }.reject(&:nil?))
          else
            @default
          end
        end
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
