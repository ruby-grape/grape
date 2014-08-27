module Grape
  module Validations
    class NonEmptyValidator < SingleOptionValidator
      def validate_param!(attr_name, params)
        value = params[attr_name]
        value = value.strip if value.respond_to?(:strip)

        if @option && value.blank?
          raise Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message: 'empty'
        end
      end
    end
  end
end
