# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      # Base class for all parameter validators.
      #
      # == Freeze contract
      # Validator instances are shared across requests and are frozen after
      # initialization (via +.new+). All inputs (+options+, +opts+, +attrs+)
      # arrive pre-frozen from the DSL boundary, so subclass ivars derived
      # from them are frozen by construction. Lazy ivar assignment
      # (e.g. +memoize+, <tt>||=</tt>) will raise +FrozenError+ at request time.
      class Base
        include Grape::Util::Translation

        attr_reader :attrs

        class << self
          # Declares the default I18n message key used by +validation_error!+.
          # Subclasses that only need a single fixed error message can declare it
          # at the class level instead of overriding +initialize+:
          #
          #   class MyValidator < Grape::Validations::Validators::Base
          #     default_message_key :my_error
          #   end
          #
          # The key is resolved through +message+, so a per-option +:message+
          # override still takes precedence.
          def default_message_key(key = nil)
            if key
              @default_message_key = key
            else
              @default_message_key || (superclass.respond_to?(:default_message_key) ? superclass.default_message_key : nil)
            end
          end

          def new(...)
            super.freeze
          end

          def inherited(klass)
            super
            Validations.register(klass)
          end
        end

        # Creates a new Validator from options specified
        # by a +requires+ or +optional+ directive during
        # parameter definition.
        # @param attrs [Array] names of attributes to which the Validator applies
        # @param options [Object] implementation-dependent Validator options; deep-frozen on assignment
        # @param required [Boolean] attribute(s) are required or optional
        # @param scope [ParamsScope] parent scope for this Validator
        # @param opts [Hash] additional validation options
        def initialize(attrs, options, required, scope, opts)
          @attrs = Array(attrs).freeze
          @options = Grape::Util::DeepFreeze.deep_freeze(options)
          @option = @options # TODO: remove in next major release
          @required = required
          @scope = scope
          @fail_fast, @allow_blank = opts.values_at(:fail_fast, :allow_blank)
          @exception_message = message(self.class.default_message_key) if self.class.default_message_key
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

        def fail_fast?
          @fail_fast
        end

        # Validates a given parameter hash.
        # @note Override #validate_param! for per-parameter validation,
        #   or #validate if you need access to the entire request.
        # @param params [Hash] parameters to validate
        # @raise [Grape::Exceptions::Validation] if validation failed
        # @return [void]
        def validate!(params)
          attributes = SingleAttributeIterator.new(@attrs, @scope, params)
          # we collect errors inside array because
          # there may be more than one error per field
          array_errors = []

          attributes.each do |val, attr_name, empty_val|
            next if !@scope.required? && empty_val
            next unless @scope.meets_dependency?(val, params)

            validate_param!(attr_name, val) if @required || (hash_like?(val) && val.key?(attr_name))
          rescue Grape::Exceptions::Validation => e
            array_errors << e
          end

          raise Grape::Exceptions::ValidationArrayErrors.new(array_errors) if array_errors.any?
        end

        protected

        # Validates a single attribute. Override in subclasses.
        # @param attr_name [Symbol, String] the attribute name
        # @param params [Hash] the parameter hash containing the attribute
        # @raise [Grape::Exceptions::Validation] if validation failed
        # @return [void]
        def validate_param!(attr_name, params)
          raise NotImplementedError
        end

        private

        def validation_error!(attr_name_or_params, message = @exception_message)
          params = attr_name_or_params.is_a?(Array) ? attr_name_or_params : @scope.full_name(attr_name_or_params)
          raise Grape::Exceptions::Validation.new(params: params, message: message)
        end

        def hash_like?(obj)
          obj.respond_to?(:key?)
        end

        def options_key?(key, options = nil)
          current_options = options || @options
          hash_like?(current_options) && current_options.key?(key) && !current_options[key].nil?
        end

        # Returns the effective message for a validation error.
        # Prefers an explicit +:message+ option, then +default_key+.
        # If both are nil, the block (if given) is called to compute a fallback —
        # useful for validators that build a message Hash for deferred i18n interpolation.
        # @example
        #   @exception_message = message(:presence)             # symbol key or custom message
        #   @exception_message = message { build_hash_message } # computed fallback
        def message(default_key = nil)
          key = options_key?(:message) ? @options[:message] : default_key
          return key unless key.nil?

          yield if block_given?
        end

        def option_value
          options_key?(:value) ? @options[:value] : @options
        end

        def scrub(value)
          return value unless value.respond_to?(:valid_encoding?) && !value.valid_encoding?

          value.scrub
        end
      end
    end
  end
end
