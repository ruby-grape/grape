module Grape
  module Validations
    class PresenceValidator < Validator
      def validate_param!(attr_name, params)
        unless params.has_key?(attr_name)
          raise Grape::Exceptions::Validation, :status => 400, :param => attr_name, :message_key => :presence
        end
      end
    end
  end
end
