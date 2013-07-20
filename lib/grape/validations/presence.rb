module Grape
  module Validations
    class PresenceValidator < Validator
      def validate!(params)
        # If this validator is for a parameter inside an optional group
        # for which params is blank, then we should skip validation
        scope = @scope
        while scope
          return if scope.optional? && scope.params(params).blank?
          scope = scope.parent
        end
        super
      end

      def validate_param!(attr_name, params)
        unless params.has_key?(attr_name)
          raise Grape::Exceptions::Validation, :status => 400,
            :param => @scope.full_name(attr_name), :message_key => :presence
        end
      end
    end
  end
end
