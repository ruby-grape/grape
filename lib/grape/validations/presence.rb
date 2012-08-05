module Grape
  module Validations
    
    class PresenceValidator < Validator
      def validate_param!(path, params)
        unless params.has_key?(path)
          throw :error, :status => 400, :message => "missing parameter: #{path}"
        end
      end
    end
    
  end
end
