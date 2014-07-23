module Grape
  module Validations
    class RegexpValidator < SingleOptionValidator
      def validate_param!(attr_name, params)
        if params.key?(attr_name) &&
          (params[attr_name].nil? || !(params[attr_name].to_s =~ @option))
          raise Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message_key: :regexp
        end
      end
    end
  end
end
