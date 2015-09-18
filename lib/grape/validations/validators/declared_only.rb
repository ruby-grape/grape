module Grape
  module Validations
    class DeclaredOnlyValidator < Base
      def validate!(params)
        validate_recursive!([], params)
        super
      end

      private

      def validate_recursive!(nested_keys, obj)
        obj.each_pair do |key, value|
          keys = nested_keys + [key]
          if value.is_a?(Hash)
            validate_recursive!(keys, value)
            next
          end
          unless @scope.declared_param?(construct_key(keys))
            fail Grape::Exceptions::Validation, params: [keys.join('.')], message_key: :declared_only
          end
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
