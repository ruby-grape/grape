module Grape
  module Validations
    class RegexpValidator < Base
      def validate_param!(attr_name, params)
        return unless params.key?(attr_name) && !params[attr_name].nil? && !(params[attr_name].to_s =~ (options_key?(:value) ? @option[:value] : @option))
        fail Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message: message(:regexp)
      end
    end
  end
end
