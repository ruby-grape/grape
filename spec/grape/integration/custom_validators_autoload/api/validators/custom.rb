module Api
  module Validators
    class Custom < Grape::Validations::Base
      def validate_param!(attr_name, params)
        params[attr_name] = 'custom_validated'
      end
    end
  end
end
