module Grape
  module Validations
    class UndeclaredValidator < Base
      def initialize(attrs, options, required, scope)
        super
        fail Grape::Exceptions::UnknownOptions.new(@option) unless [:error, :warn].include?(@option)
      end

      def validate!(params)
        validate_recursive!([], params)
        super
      end

      private

      def validate_recursive!(nested_keys, obj)
        if obj.is_a?(Hash)
          obj.each_pair do |key, value|
            keys = nested_keys + [key]
            validate_step(keys, value)
          end
        elsif obj.is_a?(Array)
          obj.each do |value|
            validate_step(nested_keys, value)
          end
        end
      end

      def validate_step(keys, value)
        if value.is_a?(Hash) || value.is_a?(Array)
          return unless @scope.declared_block?(construct_key(keys)) # skip validating for a generic hash
          validate_recursive!(keys, value)
          return
        end
        return if @scope.declared_param?(construct_key(keys))

        case @option
        when :error
          fail Grape::Exceptions::Validation, params: [keys.join('.')], message_key: :undeclared
        when :warn
          warn "#{keys.join('.')} #{Grape::Exceptions::Validation.new(params: [keys.join('.')], message_key: :undeclared)}"
        end
      end

      def construct_key(nested_keys)
        return nested_keys[0].to_sym if nested_keys.length == 1

        nested_keys = nested_keys.map(&:to_sym)
        value = [nested_keys.pop]
        nested_keys.reverse.inject(value) { |a, e| { e.to_sym => a } }
      end
    end
  end
end
