module Grape
  module Validations
    class Base
      attr_reader :attrs

      def initialize(attrs, options, required, scope)
        @attrs = Array(attrs)
        @required = required
        @scope = scope

        if options.is_a?(Hash) && !options.empty?
          raise Grape::Exceptions.UnknownOptions.new(options.keys)
        end
      end

      def validate!(params)
        attributes = AttributesIterator.new(self, @scope, params)
        attributes.each do |resource_params, attr_name|
          if @required || resource_params.key?(attr_name)
            validate_param!(attr_name, resource_params)
          end
        end
      end

      class AttributesIterator
        include Enumerable

        def initialize(validator, scope, params)
          @attrs = validator.attrs
          @params = scope.params(params)
          @params = (@params.is_a?(Array) ? @params : [@params])
        end

        def each
          @params.each do |resource_params|
            @attrs.each do |attr_name|
              yield resource_params, attr_name
            end
          end
        end
      end

      def self.inherited(klass)
        # temporary kludge
        unless klass == SingleOptionValidator
          short_name = convert_to_short_name(klass)
          Validations.register_validator(short_name, klass)
        end
      end

      def self.convert_to_short_name(klass)
        ret = klass.name.gsub(/::/, '/')
          .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
          .gsub(/([a-z\d])([A-Z])/, '\1_\2')
          .tr("-", "_")
          .downcase
        File.basename(ret, '_validator')
      end
    end
  end
end
