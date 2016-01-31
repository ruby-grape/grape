module Grape
  module Validations
    class RegexpValidator < Base
      def validate_param!(attr_name, params)
        return unless params.key?(attr_name) && !params[attr_name].nil? && !(params[attr_name].to_s =~ @option)
        fail Grape::Exceptions::Validation, params: [@scope.full_message(attr_name, param_index(params))], message_key: :regexp
      end
    end
  end
end
