module Grape
  module Validations
    class DefaultValidator < Base
      def initialize(attrs, options, required, scope)
        @default = options
        super
      end

      def validate_param!(attr_name, params, request)
        unless params.key?(attr_name)
          params[attr_name] =
          if @default.is_a?(Proc)
            @default.parameters.empty? ? @default.call : @default.call(request)
          else
            @default
          end
        end
      end

      def validate!(request)
        params = request.params
        attrs = AttributesIterator.new(self, @scope, params)
        parent_element = @scope.element
        attrs.each do |resource_params, attr_name|
          if resource_params[attr_name].nil?
            validate_param!(attr_name, resource_params, request)
            params[parent_element] = resource_params if parent_element && params[parent_element].nil?
          end
        end
      end
    end
  end
end
