module Grape

  class API
    Boolean = Virtus::Attribute::Boolean
  end
  
  module Validations
    
    class CoerceValidator < SingleOptionValidator
      def validate_param!(attr_name, params)
        new_value = coerce_value(@option, params[attr_name])
        if valid_type?(new_value)
          params[attr_name] = new_value
        else
          throw :error, :status => 400, :message => "invalid parameter: #{attr_name}"
        end
      end
  
    private
    
      def _valid_array_type?(type, values)
        values.all? do |val|
          _valid_single_type?(type, val)
        end
      end
      
      def _valid_single_type?(klass, val)
        if klass == Virtus::Attribute::Boolean
          val.is_a?(TrueClass) || val.is_a?(FalseClass)
        else
          val.is_a?(klass)
        end
      end
      
      def valid_type?(val)
        if @option.is_a?(Array)
          _valid_array_type?(@option[0], val)
        else
          _valid_single_type?(@option, val)
        end
      end
      
      def coerce_value(type, val)
        converter = Virtus::Attribute.build(:a, type)
        converter.coerce(val)
      
      # not the prettiest but some invalid coercion can currently trigger
      # errors in Virtus (see coerce_spec.rb)
      rescue
        nil
      end
      
    end
    
  end
end
