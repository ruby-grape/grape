module Grape
  module Validations
    class ValuesValidator < Base
      def initialize(attrs, options, required, scope, opts = {})
        @excepts = (options_key?(:except, options) ? options[:except] : [])
        @values = (options_key?(:value, options) ? options[:value] : [])

        @values = options if @excepts == [] && @values == []
        super
      end

      def validate_param!(attr_name, params)
        return unless params.is_a?(Hash)
        return unless params[attr_name] || required_for_root_scope?

        values = @values.is_a?(Proc) ? @values.call : @values
        excepts = @excepts.is_a?(Proc) ? @excepts.call : @excepts
        param_array = params[attr_name].nil? ? [nil] : Array.wrap(params[attr_name])

        if param_array.all? { |param| excepts.include?(param) }
          raise Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message: except_message
        end

        return if (values.is_a?(Array) && values.empty?) || param_array.all? { |param| values.include?(param) }
        raise Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message: message(:values)
      end

      private

      def except_message
        options = instance_variable_get(:@option)
        options_key?(:except_message) ? options[:except_message] : message(:except)
      end

      def required_for_root_scope?
        @required && @scope.root?
      end
    end
  end
end
