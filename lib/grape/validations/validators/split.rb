module Grape
  module Validations
    class SplitValidator < Base
      def validate_param!(attr_name, params)
        params[attr_name] = params[attr_name].split(@option)
      rescue
        InvalidValue.new
      end
    end
  end
end
