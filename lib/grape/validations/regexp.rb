module Grape
  module Validations
    
    class RegexpValidator < SingleOptionValidator
      def validate_param!(attr_name, params)
        if params[attr_name] && !( params[attr_name].to_s =~ @option )
          raise ValidationError, :status => 400, :message => "invalid parameter: #{attr_name}"
        end
      end
    end

  end
end
