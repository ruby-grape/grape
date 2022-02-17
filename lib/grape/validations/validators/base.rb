# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class Base
        attr_reader :attrs

        # Creates a new Validator from options specified
        # by a +requires+ or +optional+ directive during
        # parameter definition.
        # @param attrs [Array] names of attributes to which the Validator applies
        # @param options [Object] implementation-dependent Validator options
        # @param required [Boolean] attribute(s) are required or optional
        # @param scope [ParamsScope] parent scope for this Validator
        # @param opts [Array] additional validation options
        def initialize(attrs, options, required, scope, *opts)
          @attrs = Array(attrs)
          @option = options
          @required = required
          @scope = scope
          opts = opts.any? ? opts.shift : {}
          @fail_fast = opts.fetch(:fail_fast, false)
          @allow_blank = opts.fetch(:allow_blank, false)
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
          attributes = SingleAttributeIterator.new(self, @scope, params)
          # we collect errors inside array because
          # there may be more than one error per field
          array_errors = []

          attributes.each do |val, attr_name, empty_val, skip_value|
            next if skip_value
            next if !@scope.required? && empty_val
            next unless @scope.meets_dependency?(val, params)

            begin
              validate_param!(attr_name, val) if @required || (val.respond_to?(:key?) && val.key?(attr_name))
            rescue Grape::Exceptions::Validation => e
              array_errors << e
            end
          end

          raise Grape::Exceptions::ValidationArrayErrors.new(array_errors) if array_errors.any?
        end

        def self.convert_to_short_name(klass)
          ret = klass.name.gsub(/::/, '/')
          ret.gsub!(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
          ret.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
          ret.tr!('-', '_')
          ret.downcase!
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
end

Grape::Validations::Base = Class.new(Grape::Validations::Validators::Base) do
  def initialize(*)
    super
    warn '[DEPRECATION] `Grape::Validations::Base` is deprecated. Use `Grape::Validations::Validators::Base` instead.'
  end
end
