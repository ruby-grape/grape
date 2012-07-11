module Grape
  module Validations
    
    class CoerceValidator < SingleOptionValidator
      def validate_param!(attr_name, params)
        params[attr_name] = coerce_value(@option, params[attr_name])
      end
  
    private
      def coerce_value(type, val)
        converter = Virtus::Attribute.build(:a, type)
        converter.coerce(val)
      end
    end
    
  end
end
