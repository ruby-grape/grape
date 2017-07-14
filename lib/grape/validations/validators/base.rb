module Grape
  module Validations
    class Base
      attr_reader :attrs

      # Creates a new Validator from options specified
      # by a +requires+ or +optional+ directive during
      # parameter definition.
      # @param attrs [Array] names of attributes to which the Validator applies
      # @param options [Object] implementation-dependent Validator options
      # @param required [Boolean] attribute(s) are required or optional
      # @param scope [ParamsScope] parent scope for this Validator
      # @param opts [Hash] additional validation options
      def initialize(attrs, options, required, scope, opts = {})
        @attrs = Array(attrs)
        @option = options
        @required = required
        @scope = scope
        @fail_fast = opts[:fail_fast] || false
      end

      # Validates a given request.
      # @note Override #validate! unless you need to access the entire request.
      # @param request [Grape::Request] the request currently being handled
      # @raise [Grape::Exceptions::Validation] if validation failed
      # @return [void]
      def validate(request)
        return unless @scope.should_validate?(request.params)
        validate!(request.params)
      end

      # Validates a given parameter hash.
      # @note Override #validate if you need to access the entire request.
      # @param params [Hash] parameters to validate
      # @raise [Grape::Exceptions::Validation] if validation failed
      # @return [void]
      def validate!(params)
        attributes = AttributesIterator.new(self, @scope, params)
        array_errors = []
        attributes.each do |resource_params, attr_name|
          next unless @required || (resource_params.respond_to?(:key?) && resource_params.key?(attr_name))
          next unless @scope.meets_dependency?(resource_params, params)

          begin
            validate_param!(attr_name, resource_params)
          rescue Grape::Exceptions::Validation => e
            # we collect errors inside array because
            # there may be more than one error per field
            array_errors << e
          end
        end

        raise Grape::Exceptions::ValidationArrayErrors, array_errors if array_errors.any?
      end

      def self.convert_to_short_name(klass)
        ret = klass.name.gsub(/::/, '/')
                   .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
                   .gsub(/([a-z\d])([A-Z])/, '\1_\2')
                   .tr('-', '_')
                   .downcase
        File.basename(ret, '_validator')
      end

      def self.inherited(klass)
        return unless klass.name.present?
        Validations.register_validator(convert_to_short_name(klass), klass)
      end

      def message(default_key = nil)
        options = instance_variable_get(:@option)
        options_key?(:message) ? options[:message] : default_key
      end

      def options_key?(key, options = nil)
        options = instance_variable_get(:@option) if options.nil?
        options.respond_to?(:key?) && options.key?(key) && !options[key].nil?
      end

      def fail_fast?
        @fail_fast
      end
    end
  end
end
