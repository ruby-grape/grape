module Grape
  class API
    Boolean = Virtus::Attribute::Boolean
  end

  module Validations
    class CoerceValidator < Base
      def validate_param!(attr_name, params)
        fail Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message_key: :coerce unless params.is_a? Hash
        new_value = coerce_value(params[attr_name])
        if valid_type?(new_value)
          params[attr_name] = new_value
        else
          fail Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message_key: :coerce
        end
      end

      private

      def valid_type?(val)
        # Special value to denote coercion failure
        return false if val.instance_of?(Types::InvalidValue)

        # Allow nil, to ignore when a parameter is absent
        return true if val.nil?

        converter.value_coerced? val
      end

      def coerce_value(val)
        # Don't coerce things other than nil to Arrays or Hashes
        unless (@option[:method] && !val.nil?) || type.is_a?(Virtus::Attribute)
          return val || []      if type == Array
          return val || Set.new if type == Set
          return val || {}      if type == Hash
        end

        converter.coerce(val)

      # not the prettiest but some invalid coercion can currently trigger
      # errors in Virtus (see coerce_spec.rb:75)
      rescue
        Types::InvalidValue.new
      end

      # Type to which the parameter will be coerced.
      #
      # @return [Class]
      def type
        @option[:type]
      end

      # Create and cache the attribute object
      # that will be used for parameter coercion
      # and type checking.
      #
      # See {Types.build_coercer}
      #
      # @return [Virtus::Attribute]
      def converter
        @converter ||= Types.build_coercer(type, @option[:method])
      end
    end
  end
end
