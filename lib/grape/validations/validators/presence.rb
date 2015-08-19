module Grape
  module Validations
    class PresenceValidator < Base
      def validate!(params)
        return unless @scope.should_validate?(params)
        super
      end

      def validate_param!(attr_name, params)
        return if params.respond_to?(:key?) && params.key?(attr_name)
        fail Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message_key: :presence
      end
    end
  end
end
