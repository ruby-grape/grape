module Grape
  module Validations
    class ValuesValidator < Base
      def initialize(attrs, options, required, scope, opts = {})
        if options.is_a?(Hash)
          @excepts = options[:except]
          @values = options[:value]
          @proc = options[:proc]
          raise ArgumentError, 'proc must be a Proc' if @proc && !@proc.is_a?(Proc)
        else
          @values = options
        end
        super
      end

      def validate_param!(attr_name, params)
        return unless params.is_a?(Hash)
        return unless params[attr_name] || required_for_root_scope?

        values = @values.is_a?(Proc) ? @values.call : @values
        excepts = @excepts.is_a?(Proc) ? @excepts.call : @excepts
        param_array = params[attr_name].nil? ? [nil] : Array.wrap(params[attr_name])

        raise Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message: except_message \
          if !excepts.nil? && param_array.any? { |param| excepts.include?(param) }

        raise Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message: message(:values) \
          if !values.nil? && !param_array.all? { |param| values.include?(param) }

        raise Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message: message(:values) \
          if @proc && !param_array.all? { |param| @proc.call(param) }
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
