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
        elsif type == JSON
          # Special JSON type is ambiguously defined.
          # We allow both objects and arrays.
          val.is_a?(Hash) || _valid_array_type?(Hash, val)
        elsif type == Array[JSON]
          # Array[JSON] shorthand wraps single objects.
          _valid_array_type?(Hash, val)
        elsif type.is_a?(Array) || type.is_a?(Set)
          _valid_array_type?(type.first, val)
        else
          _valid_single_type?(type, val)
        end
      end

      def coerce_value(val)
        # JSON is not a type as Virtus understands it,
        # so we bypass normal coercion.
        if type == JSON
          return val ? JSON.parse(val, symbolize_names: true) : {}
        elsif type == Array[JSON]
          return val ? Array.wrap(JSON.parse(val, symbolize_names: true)) : []
        end

        # Don't coerce things other than nil to Arrays or Hashes
        unless @option[:method] && !val.nil?
          return val || []      if type == Array
          return val || Set.new if type == Set
          return val || {}      if type == Hash
        end

        converter.coerce(val)

      # not the prettiest but some invalid coercion can currently trigger
      # errors in Virtus (see coerce_spec.rb:75)
      rescue
        InvalidValue.new
      end

      def type
        @option[:type]
      end

      def converter
        @converter ||=
          begin
            # If any custom conversion method has been supplied
            # via the coerce_with parameter, pass it on to Virtus.
            converter_options = {}
            if @option[:method]
              # Accept classes implementing parse()
              coercer = if @option[:method].respond_to? :parse
                          @option[:method].method(:parse)
                        else
                          # Otherwise expect a lambda function or similar
                          @option[:method]
                        end

              # Enforce symbolized keys for complex types
              # by wrapping the coercion method.
              # This helps common libs such as JSON to work easily.
              if type == Array || type == Set
                converter_options[:coercer] = lambda do |val|
                  coercer.call(val).tap do |new_value|
                    new_value.each do |item|
                      Hashie.symbolize_keys!(item) if item.is_a? Hash
                    end
                  end
                end
              elsif type == Hash
                converter_options[:coercer] = lambda do |val|
                  Hashie.symbolize_keys! coercer.call(val)
                end
              else
                # Simple types do not need a wrapper
                converter_options[:coercer] = coercer
              end

            # Custom types may be used without an explicit coercion method
            # if they implement a `parse` class method.
            elsif ParameterTypes.custom_type?(type)
              converter_options[:coercer] = type.method(:parse)
            end

            Virtus::Attribute.build(type, converter_options)
          end
      end
    end
  end
end
