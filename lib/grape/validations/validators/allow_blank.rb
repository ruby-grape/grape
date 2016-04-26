module Grape
  module Validations
    class AllowBlankValidator < Base
      def validate_param!(attr_name, params)
        return if (options_key?(:value) ? @option[:value] : @option) || !params.is_a?(Hash)

        value = params[attr_name]
        value = value.strip if value.respond_to?(:strip)

        key_exists = params.key?(attr_name)

        should_validate = if @scope.root?
                            # root scope. validate if it's a required param. if it's optional, validate only if key exists in hash
                            @required || key_exists
                          else # nested scope
                            (@required && params.present?) ||
                              # optional param but key inside scoping element exists
                              (!@required && params.key?(attr_name))
                          end

        return unless should_validate

        return if value == false || value.present?

        raise Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message: message(:blank)
      end
    end
  end
end
