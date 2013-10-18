module Grape
  module Validations
    class DefaultValidator < Validator
      def initialize(attrs, options, required, scope)
        @default = options
        super
      end

      def validate_param!(attr_name, params)
        params[attr_name] = @default unless params.has_key?(attr_name)
      end

      def validate!(params)
        params = AttributesIterator.new(self, @scope, params)
        params.each do |resource_params, attr_name|
          if resource_params[attr_name].nil?
            validate_param!(attr_name, resource_params)
          end
        end
      end
    end
  end
end
