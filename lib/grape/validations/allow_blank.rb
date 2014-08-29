module Grape
  module Validations
    class AllowBlankValidator < Validator
      def initialize(attrs, options, required, scope)
        @option = options
        @required = required
        super
      end

      def validate_param!(attr_name, params)
        return if @option

        value = params[attr_name]
        value = value.strip if value.respond_to?(:strip)

        key_exists = params.key?(attr_name)

        if @scope.root?
          # root scope. validate if it's a required param. if it's optional, validate only if key exists in hash
          should_validate = @required || key_exists
        else # nested scope
          should_validate = # required param, and scope contains some values (if scoping element contains no values, treat as blank)
            (@required && params.present?) ||
            # optional param but key inside scoping element exists
            (!@required && params.key?(attr_name))
        end

        return unless should_validate

        unless value.present?
          raise Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message_key: :blank
        end
      end
    end
  end
end
