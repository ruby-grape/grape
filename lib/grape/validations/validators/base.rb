# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      # Base class for all parameter validators.
      #
      # == Freeze contract
      # Validator instances are shared across requests and are frozen after
      # initialization (via +.new+). #initialize freezes +attrs+ and
      # deep-freezes +options+, so subclass ivars derived from them are frozen
      # by construction. Lazy ivar assignment (e.g. +memoize+, <tt>||=</tt>)
      # will raise +FrozenError+ at request time.
      class Base
        extend Forwardable
        extend Grape::Util::FreezeOnNew
        include Grape::Util::Translation

        attr_reader :attrs

        # +allow_blank+ / +fail_fast+ are read straight off the internal
        # {Grape::Validations::SharedOptions} value object; no per-validator
        # ivars. The object is built from the +opts+ Hash in #initialize, so
        # the public 5th-argument contract stays a plain Hash.
        def_delegators :@opts, :allow_blank, :fail_fast

        alias fail_fast? fail_fast
        alias allow_blank? allow_blank

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
        # @param opts [Hash] shared validator options; only +:allow_blank+ and
        #   +:fail_fast+ are consulted (other keys ignored, as before)
        def initialize(attrs, options, required, scope, opts)
          @attrs = Array(attrs).freeze
          @options = Grape::Util::DeepFreeze.deep_freeze(options)
          @required = required
          @scope = scope
          @opts = SharedOptions.new(**opts.slice(:allow_blank, :fail_fast))
          @exception_message = message(self.class.default_message_key) if self.class.default_message_key
          @iterator = iterator_class.new(@attrs, @scope).freeze
          # A scope's parent, optionality, dependency and type are all set
          # before its block declares anything, so these are settled by the
          # time a validator is built. See #validate and #validate!.
          @always_validated = scope.always_validated?
          @direct = @always_validated && !scope.iterates_elements?
          @direct_elements = scope.validated_when_given? && scope.iterates_elements? && scope.array_depth == 1
        end

        # Validates a given request.
        # @note Override #validate! unless you need to access the entire request.
        # @param request [Grape::Request] the request currently being handled
        # @raise [Grape::Exceptions::Validation] if validation failed
        # @return [void]
        def validate(request)
          params = request.params
          return unless @always_validated || scope.should_validate?(params)

          validate!(params)
        end

        # Validates a given parameter hash.
        # @note Override #validate_param! for per-parameter validation,
        #   or #validate if you need access to the entire request.
        # @param params [Hash] parameters to validate
        # @raise [Grape::Exceptions::Validation] if validation failed
        # @return [void]
        def validate!(params)
          return validate_elements!(scope.params(params)) if @direct_elements

          scoped = scope.params(params) if @direct
          return validate_attributes!(scoped) if scoped.is_a?(Hash)

          # we collect errors inside array because
          # there may be more than one error per field
          array_errors = nil

          @iterator.each(params) do |val, attr_name, empty_val|
            next if !scope.required? && empty_val
            next unless scope.meets_dependency?(val, params)

            validate_param!(attr_name, val) if required? || (hash_like?(val) && val.key?(attr_name))
          rescue Grape::Exceptions::Validation => e
            (array_errors ||= []) << e
          end

          raise Grape::Exceptions::ValidationArrayErrors.new(array_errors) if array_errors
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

        attr_reader :options, :scope, :required, :exception_message

        alias required? required

        # #validate! on a scope that always validates and does not iterate
        # elements, once its params resolved to a Hash: the root scope and the
        # required Hash scopes under it, which is most validators of most
        # endpoints. There the iterator hands back that Hash once per
        # attribute, and every scope on the chain is required with no
        # dependency, so the per-attribute checks reduce to this. The
        # machinery cost more than the validation itself.
        def validate_attributes!(params)
          array_errors = nil

          @attrs.each do |attr_name|
            validate_param!(attr_name, params) if required? || params.key?(attr_name)
          rescue Grape::Exceptions::Validation => e
            (array_errors ||= []) << e
          end

          raise Grape::Exceptions::ValidationArrayErrors.new(array_errors) if array_errors
        end

        # #validate_attributes! for each element of an Array scope, such as
        # +requires :items, type: Array do+ at the root, when it is the only
        # scope on the chain that iterates elements: its params are then the
        # request's Array as it came in, with no nesting for the iterator to
        # descend into. It depends on no other param and every scope above it
        # is always validated, so the iterator's per-element checks come down
        # to the index it records for the error names and, for an optional
        # scope, passing over an empty element. An element that is not a Hash
        # goes through the same +hash_like?+ test as on the iterator path, and
        # the members of a scope that did not get an Array are left alone, as
        # they are there: the scope's own type check reports it.
        def validate_elements!(elements)
          return unless elements.is_a?(Array)

          tracker = ParamScopeTracker.current
          optional = !scope.required?
          array_errors = nil

          elements.each_with_index do |element, index|
            tracker&.store_index(scope, index)
            next if optional && empty_element?(element)

            @attrs.each do |attr_name|
              validate_param!(attr_name, element) if required? || (hash_like?(element) && element.key?(attr_name))
            rescue Grape::Exceptions::Validation => e
              (array_errors ||= []) << e
            end
          end

          raise Grape::Exceptions::ValidationArrayErrors.new(array_errors) if array_errors
        end

        # What the iterator passes over in an optional scope: an element given
        # empty, or the placeholder +map_params+ puts where an optional scope's
        # params were not given at all, which it can only do here when a scope
        # above was handed an Array instead of a Hash.
        def empty_element?(element)
          return true if Grape::DSL::Parameters::EmptyOptionalValue.equal?(element)

          element.respond_to?(:empty?) ? element.empty? : element.nil?
        end

        # The AttributesIterator subclass used to walk this validator's
        # attributes. Built once in #initialize and reused across requests.
        def iterator_class
          SingleAttributeIterator
        end

        def validation_error!(attr_name_or_params, message = exception_message)
          params = attr_name_or_params.is_a?(Array) ? attr_name_or_params : scope.full_name(attr_name_or_params)
          raise Grape::Exceptions::Validation.new(params:, message:)
        end

        def hash_like?(obj)
          obj.respond_to?(:key?)
        end

        def options_key?(key, given_options = nil)
          current_options = given_options || options
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
          key = options_key?(:message) ? options[:message] : default_key
          return key unless key.nil?

          yield if block_given?
        end

        def option_value
          options_key?(:value) ? options[:value] : options
        end

        def scrub(value)
          return value if !value.respond_to?(:valid_encoding?) || value.valid_encoding?

          value.scrub
        end
      end
    end
  end
end
