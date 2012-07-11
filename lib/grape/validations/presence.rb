module Grape
  module Validations
    
    class PresenceValidator < Validator
      def validate_param!(attr_name, params)
        unless params.has_key?(attr_name)
          throw :error, :status => 400, :message => "missing parameter: #{attr_name}"
        end
      end
    
    end
    
  end
end
