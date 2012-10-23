module Grape
  module Validations
    class PresenceValidator < Validator
      def validate_param!(attr_name, params)
        unless params.has_key?(attr_name)
          raise Grape::Exceptions::ValidationError, :status => 400, :param => attr_name, :message => "missing parameter: #{attr_name}"
        end
      end
    end
  end
end
