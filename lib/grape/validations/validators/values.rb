module Grape
  module Validations
    class ValuesValidator < Base
      def initialize(attrs, options, required, scope)
        @values = (options_key?(:value, options) ? options[:value] : options)
        super
      end

      def validate_param!(attr_name, params)
        return unless params.is_a?(Hash)
        return unless params[attr_name] || required_for_root_scope?

        values = @values.is_a?(Proc) ? @values.call : @values
        values = values.to_a if values.is_a? Range
        param_array = params[attr_name].nil? ? [nil] : Array.wrap(params[attr_name])
        return if param_array.all? { |param| values.include?(param) }
        raise Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message: message(:values)
      end

      private

      def required_for_root_scope?
        @required && @scope.root?
      end
    end
  end
end
