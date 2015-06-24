module Grape
  class API
    Boolean = Virtus::Attribute::Boolean # rubocop:disable ConstantName
  end

  module Validations
    class CoerceValidator < Base
      def validate_param!(attr_name, params)
        fail Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message_key: :coerce unless params.is_a? Hash
        new_value = coerce_value(@option, params[attr_name])
        if valid_type?(new_value)
          params[attr_name] = new_value
        else
          fail Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message_key: :coerce
        end
      end

      class InvalidValue; end

      private

      def _valid_array_type?(type, values)
        values.all? do |val|
          _valid_single_type?(type, val)
        end
      end

      def _valid_single_type?(klass, val)
        # allow nil, to ignore when a parameter is absent
        return true if val.nil?
        if klass == Virtus::Attribute::Boolean
          val.is_a?(TrueClass) || val.is_a?(FalseClass) || (val.is_a?(String) && val.empty?)
        elsif klass == Rack::Multipart::UploadedFile
          val.is_a?(Hashie::Mash) && val.key?(:tempfile)
        elsif [DateTime, Date, Numeric].any? { |vclass| vclass >= klass }
          return true if val.is_a?(String) && val.empty?
          val.is_a?(klass)
        else
          val.is_a?(klass)
        end
      end

      def valid_type?(val)
        if val.instance_of?(InvalidValue)
          false
        elsif @option.is_a?(Array) || @option.is_a?(Set)
          _valid_array_type?(@option.first, val)
        else
          _valid_single_type?(@option, val)
        end
      end

      def coerce_value(type, val)
        # Don't coerce things other than nil to Arrays or Hashes
        return val || []      if type == Array
        return val || Set.new if type == Set
        return val || {}      if type == Hash

        # To support custom types that Virtus can't easily coerce, pass in an
        # explicit coercer. Custom types must implement a `parse` class method.
        converter_options = {}
        if ParameterTypes.custom_type?(type)
          converter_options[:coercer] = type.method(:parse)
        end

        converter = Virtus::Attribute.build(type, converter_options)
        converter.coerce(val)

      # not the prettiest but some invalid coercion can currently trigger
      # errors in Virtus (see coerce_spec.rb:75)
      rescue
        InvalidValue.new
      end
    end
  end
end
