module Grape
  module Validations

    class RegexpValidator < SingleOptionValidator
      def validate_param!(attr_name, params)
        if params[attr_name] && !(params[attr_name].to_s =~ @option)
          raise Grape::Exceptions::Validation, param: @scope.full_name(attr_name), message_key: :regexp
        end
      end
    end

  end
end
