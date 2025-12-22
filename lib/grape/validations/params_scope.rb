# frozen_string_literal: true

module Grape
  module Validations
    class ParamsScope
      attr_accessor :element, :parent, :index
      attr_reader :type, :params_meeting_dependency

      include Grape::DSL::Parameters
      include Grape::Validations::ParamsDocumentation

      # There are a number of documentation options on entities that don't have
      # corresponding validators. Since there is nowhere that enumerates them all,
      # we maintain a list of them here and skip looking up validators for them.
      RESERVED_DOCUMENTATION_KEYWORDS = %i[as required param_type is_array format example].freeze

      SPECIAL_JSON = [JSON, Array[JSON]].freeze

      class Attr
        attr_accessor :key, :scope

        # Open up a new ParamsScope::Attr
        # @param key [Hash, Symbol] key of attr
        # @param scope [Grape::Validations::ParamsScope] scope of attr
        def initialize(key, scope)
          @key = key
          @scope = scope
        end

        # @return Array[Symbol, Hash[Symbol => Array]] declared_params with symbol instead of Attr
        def self.attrs_keys(declared_params)
          declared_params.map do |declared_param_attr|
            attr_key(declared_param_attr)
          end
        end

        def self.attr_key(declared_param_attr)
          return attr_key(declared_param_attr.key) if declared_param_attr.is_a?(self)

          if declared_param_attr.is_a?(Hash)
            declared_param_attr.transform_values { |value| attrs_keys(value) }
          else
            declared_param_attr
          end
        end
      end

      # Open up a new ParamsScope, allowing parameter definitions per
      #   Grape::DSL::Params.
      # @param opts [Hash] options for this scope
      # @option opts :element [Symbol] the element that contains this scope; for
      #   this to be relevant, @parent must be set
      # @option opts :element_renamed [Symbol, nil] whenever this scope should
      #   be renamed and to what, given +nil+ no renaming is done
      # @option opts :parent [ParamsScope] the scope containing this scope
      # @option opts :api [API] the API endpoint to modify
      # @option opts :optional [Boolean] whether or not this scope needs to have
      #   any parameters set or not
      # @option opts :type [Class] a type meant to govern this scope (deprecated)
      # @option opts :type [Hash] group options for this scope
      # @option opts :dependent_on [Symbol] if present, this scope should only
      #   validate if this param is present in the parent scope
      # @yield the instance context, open for parameter definitions
      def initialize(opts, &block)
        @element          = opts[:element]
        @element_renamed  = opts[:element_renamed]
        @parent           = opts[:parent]
        @api              = opts[:api]
        @optional         = opts[:optional] || false
        @type             = opts[:type]
        @group            = opts[:group]
        @dependent_on     = opts[:dependent_on]
        @params_meeting_dependency = []
        @declared_params = []
        @index = nil

        instance_eval(&block) if block

        configure_declared_params
      end

      def configuration
        (@api.configuration.respond_to?(:evaluate) && @api.configuration.evaluate) || @api.configuration
      end

      # @return [Boolean] whether or not this entire scope needs to be
      #   validated
      def should_validate?(parameters)
        scoped_params = params(parameters)

        return false if @optional && (scoped_params.blank? || all_element_blank?(scoped_params))
        return false unless meets_dependency?(scoped_params, parameters)
        return true if parent.nil?

        parent.should_validate?(parameters)
      end

      def meets_dependency?(params, request_params)
        return true unless @dependent_on
        return false if @parent.present? && !@parent.meets_dependency?(@parent.params(request_params), request_params)

        if params.is_a?(Array)
          @params_meeting_dependency = params.flatten.filter { |param| meets_dependency?(param, request_params) }
          return @params_meeting_dependency.present?
        end

        meets_hash_dependency?(params)
      end

      def attr_meets_dependency?(params)
        return true unless @dependent_on
        return false if @parent.present? && !@parent.attr_meets_dependency?(params)

        meets_hash_dependency?(params)
      end

      def meets_hash_dependency?(params)
        # params might be anything what looks like a hash, so it must implement a `key?` method
        return false unless params.respond_to?(:key?)

        @dependent_on.each do |dependency|
          if dependency.is_a?(Hash)
            dependency_key = dependency.keys[0]
            proc = dependency.values[0]
            return false unless proc.call(params[dependency_key])
          elsif params[dependency].blank?
            return false
          end
        end

        true
      end

      # @return [String] the proper attribute name, with nesting considered.
      def full_name(name, index: nil)
        if nested?
          # Find our containing element's name, and append ours.
          "#{@parent.full_name(@element)}#{brackets(index || @index)}#{brackets(name)}"
        elsif lateral?
          # Find the name of the element as if it was at the same nesting level
          # as our parent. We need to forward our index upward to achieve this.
          @parent.full_name(name, index: @index)
        else
          # We must be the root scope, so no prefix needed.
          name.to_s
        end
      end

      def brackets(val)
        "[#{val}]" if val
      end

      # @return [Boolean] whether or not this scope is the root-level scope
      def root?
        !@parent
      end

      # A nested scope is contained in one of its parent's elements.
      # @return [Boolean] whether or not this scope is nested
      def nested?
        @parent && @element
      end

      # A lateral scope is subordinate to its parent, but its keys are at the
      # same level as its parent and thus is not contained within an element.
      # @return [Boolean] whether or not this scope is lateral
      def lateral?
        @parent && !@element
      end

      # @return [Boolean] whether or not this scope needs to be present, or can
      #   be blank
      def required?
        !@optional
      end

      def reset_index
        @index = nil
      end

      protected

      # Adds a parameter declaration to our list of validations.
      # @param attrs [Array] (see Grape::DSL::Parameters#requires)
      def push_declared_params(attrs, opts = {})
        opts[:declared_params_scope] = self unless opts.key?(:declared_params_scope)
        return @parent.push_declared_params(attrs, opts) if lateral?

        push_renamed_param(full_path + [attrs.first], opts[:as]) if opts[:as]
        @declared_params.concat(attrs.map { |attr| ::Grape::Validations::ParamsScope::Attr.new(attr, opts[:declared_params_scope]) })
      end

      # Get the full path of the parameter scope in the hierarchy.
      #
      # @return [Array<Symbol>] the nesting/path of the current parameter scope
      def full_path
        if nested?
          (@parent.full_path + [@element])
        elsif lateral?
          @parent.full_path
        else
          []
        end
      end

      private

      # Add a new parameter which should be renamed when using the +#declared+
      # method.
      #
      # @param path [Array<String, Symbol>] the full path of the parameter
      #   (including the parameter name as last array element)
      # @param new_name [String, Symbol] the new name of the parameter (the
      #   renamed name, with the +as: ...+ semantic)
      def push_renamed_param(path, new_name)
        api_route_setting = @api.inheritable_setting.route
        base = api_route_setting[:renamed_params] || {}
        base[Array(path).map(&:to_s)] = new_name.to_s
        api_route_setting[:renamed_params] = base
      end

      def require_required_and_optional_fields(context, opts)
        except_fields = Array.wrap(opts[:except])
        using_fields = opts[:using].keys.delete_if { |f| except_fields.include?(f) }

        if context == :all
          optional_fields = except_fields
          required_fields = using_fields
        else # context == :none
          required_fields = except_fields
          optional_fields = using_fields
        end
        required_fields.each do |field|
          field_opts = opts[:using][field]
          raise ArgumentError, "required field not exist: #{field}" unless field_opts

          requires(field, **field_opts)
        end
        optional_fields.each do |field|
          field_opts = opts[:using][field]
          optional(field, **field_opts) if field_opts
        end
      end

      def require_optional_fields(context, opts)
        optional_fields = opts[:using].keys
        unless context == :all
          except_fields = Array.wrap(opts[:except])
          optional_fields.delete_if { |f| except_fields.include?(f) }
        end
        optional_fields.each do |field|
          field_opts = opts[:using][field]
          optional(field, **field_opts) if field_opts
        end
      end

      def validate_attributes(attrs, opts, &block)
        validations = opts.clone
        validations[:type] ||= Array if block
        validates(attrs, validations)
      end

      # Returns a new parameter scope, subordinate to the current one and nested
      # under the parameter corresponding to `attrs.first`.
      # @param attrs [Array] the attributes passed to the `requires` or
      #   `optional` invocation that opened this scope.
      # @param optional [Boolean] whether the parameter this are nested under
      #   is optional or not (and hence, whether this block's params will be).
      # @yield parameter scope
      def new_scope(attrs, opts, optional = false, &)
        # if required params are grouped and no type or unsupported type is provided, raise an error
        type = opts[:type]
        if attrs.first && !optional
          raise Grape::Exceptions::MissingGroupType if type.nil?
          raise Grape::Exceptions::UnsupportedGroupType unless Grape::Validations::Types.group?(type)
        end

        self.class.new(
          api: @api,
          element: attrs.first,
          element_renamed: opts[:as],
          parent: self,
          optional: optional,
          type: type || Array,
          group: @group,
          &
        )
      end

      # Returns a new parameter scope, not nested under any current-level param
      # but instead at the same level as the current scope.
      # @param options [Hash] options to control how this new scope behaves
      # @option options :dependent_on [Symbol] if given, specifies that this
      #   scope should only validate if this parameter from the above scope is
      #   present
      # @yield parameter scope
      def new_lateral_scope(options, &)
        self.class.new(
          api: @api,
          element: nil,
          parent: self,
          options: @optional,
          type: type == Array ? Array : Hash,
          dependent_on: options[:dependent_on],
          &
        )
      end

      # Returns a new parameter scope, subordinate to the current one and nested
      # under the parameter corresponding to `attrs.first`.
      # @param attrs [Array] the attributes passed to the `requires` or
      #   `optional` invocation that opened this scope.
      # @yield parameter scope
      def new_group_scope(attrs, &)
        self.class.new(api: @api, parent: self, group: attrs.first, &)
      end

      # Pushes declared params to parent or settings
      def configure_declared_params
        push_renamed_param(full_path, @element_renamed) if @element_renamed

        if nested?
          @parent.push_declared_params [element => @declared_params]
        else
          @api.inheritable_setting.namespace_stackable[:declared_params] = @declared_params
        end

        # params were stored in settings, it can be cleaned from the params scope
        @declared_params = nil
      end

      def validates(attrs, validations)
        coerce_type = infer_coercion(validations)
        required = validations.key?(:presence)
        default = validations[:default]
        values = validations[:values].is_a?(Hash) ? validations.dig(:values, :value) : validations[:values]
        except_values = validations[:except_values].is_a?(Hash) ? validations.dig(:except_values, :value) : validations[:except_values]

        # NB. values and excepts should be nil, Proc, Array, or Range.
        # Specifically, values should NOT be a Hash
        # use values or excepts to guess coerce type when stated type is Array
        coerce_type = guess_coerce_type(coerce_type, values, except_values)

        # default value should be present in values array, if both exist and are not procs
        check_incompatible_option_values(default, values, except_values)

        # type should be compatible with values array, if both exist
        validate_value_coercion(coerce_type, values, except_values)

        document_params attrs, validations, coerce_type, values, except_values

        opts = derive_validator_options(validations)

        # Validate for presence before any other validators
        validates_presence(validations, attrs, opts)

        # Before we run the rest of the validators, let's handle
        # whatever coercion so that we are working with correctly
        # type casted values
        coerce_type validations, attrs, required, opts

        validations.each do |type, options|
          # Don't try to look up validators for documentation params that don't have one.
          next if RESERVED_DOCUMENTATION_KEYWORDS.include?(type)

          validate(type, options, attrs, required, opts)
        end
      end

      # Validate and comprehend the +:type+, +:types+, and +:coerce_with+
      # options that have been supplied to the parameter declaration.
      # The +:type+ and +:types+ options will be removed from the
      # validations list, replaced appropriately with +:coerce+ and
      # +:coerce_with+ options that will later be passed to
      # {Validators::CoerceValidator}. The type that is returned may be
      # used for documentation and further validation of parameter
      # options.
      #
      # @param validations [Hash] list of validations supplied to the
      #   parameter declaration
      # @return [class-like] type to which the parameter will be coerced
      # @raise [ArgumentError] if the given type options are invalid
      def infer_coercion(validations)
        raise ArgumentError, ':type may not be supplied with :types' if validations.key?(:type) && validations.key?(:types)

        validations[:coerce] = (options_key?(:type, :value, validations) ? validations[:type][:value] : validations[:type]) if validations.key?(:type)
        validations[:coerce_message] = (options_key?(:type, :message, validations) ? validations[:type][:message] : nil) if validations.key?(:type)
        validations[:coerce] = (options_key?(:types, :value, validations) ? validations[:types][:value] : validations[:types]) if validations.key?(:types)
        validations[:coerce_message] = (options_key?(:types, :message, validations) ? validations[:types][:message] : nil) if validations.key?(:types)

        validations.delete(:types) if validations.key?(:types)

        coerce_type = validations[:coerce]

        # Special case - when the argument is a single type that is a
        # variant-type collection.
        if Types.multiple?(coerce_type) && validations.key?(:type)
          validations[:coerce] = Types::VariantCollectionCoercer.new(
            coerce_type,
            validations.delete(:coerce_with)
          )
        end
        validations.delete(:type)

        coerce_type
      end

      # Enforce correct usage of :coerce_with parameter.
      # We do not allow coercion without a type, nor with
      # +JSON+ as a type since this defines its own coercion
      # method.
      def check_coerce_with(validations)
        return unless validations.key?(:coerce_with)
        # type must be supplied for coerce_with..
        raise ArgumentError, 'must supply type for coerce_with' unless validations.key?(:coerce)

        # but not special JSON types, which
        # already imply coercion method
        return unless SPECIAL_JSON.include?(validations[:coerce])

        raise ArgumentError, 'coerce_with disallowed for type: JSON'
      end

      # Add type coercion validation to this scope,
      # if any has been specified.
      # This validation has special handling since it is
      # composited from more than one +requires+/+optional+
      # parameter, and needs to be run before most other
      # validations.
      def coerce_type(validations, attrs, required, opts)
        check_coerce_with(validations)

        return unless validations.key?(:coerce)

        coerce_options = {
          type: validations[:coerce],
          method: validations[:coerce_with],
          message: validations[:coerce_message]
        }
        validate('coerce', coerce_options, attrs, required, opts)
        validations.delete(:coerce_with)
        validations.delete(:coerce)
        validations.delete(:coerce_message)
      end

      def guess_coerce_type(coerce_type, *values_list)
        return coerce_type unless coerce_type == Array

        values_list.each do |values|
          next if !values || values.is_a?(Proc)
          return values.first.class if values.is_a?(Range) || !values.empty?
        end
        coerce_type
      end

      def check_incompatible_option_values(default, values, except_values)
        return unless default && !default.is_a?(Proc)

        raise Grape::Exceptions::IncompatibleOptionValues.new(:default, default, :values, values) if values && !values.is_a?(Proc) && !Array(default).all? { |def_val| values.include?(def_val) }

        return unless except_values && !except_values.is_a?(Proc) && Array(default).any? { |def_val| except_values.include?(def_val) }

        raise Grape::Exceptions::IncompatibleOptionValues.new(:default, default, :except, except_values)
      end

      def validate(type, options, attrs, required, opts)
        validator_options = {
          attributes: attrs,
          options: options,
          required: required,
          params_scope: self,
          opts: opts,
          validator_class: Validations.require_validator(type)
        }
        @api.inheritable_setting.namespace_stackable[:validations] = validator_options
      end

      def validate_value_coercion(coerce_type, *values_list)
        return unless coerce_type

        coerce_type = coerce_type.first if coerce_type.is_a?(Enumerable)
        values_list.each do |values|
          next if !values || values.is_a?(Proc)

          value_types = values.is_a?(Range) ? [values.begin, values.end].compact : values
          value_types = value_types.map { |type| Grape::API::Boolean.build(type) } if coerce_type == Grape::API::Boolean
          raise Grape::Exceptions::IncompatibleOptionValues.new(:type, coerce_type, :values, values) unless value_types.all?(coerce_type)
        end
      end

      def extract_message_option(attrs)
        return nil unless attrs.is_a?(Array)

        opts = attrs.last.is_a?(Hash) ? attrs.pop : {}
        opts.key?(:message) && !opts[:message].nil? ? opts.delete(:message) : nil
      end

      def options_key?(type, key, validations)
        validations[type].respond_to?(:key?) && validations[type].key?(key) && !validations[type][key].nil?
      end

      def all_element_blank?(scoped_params)
        scoped_params.respond_to?(:all?) && scoped_params.all?(&:blank?)
      end

      # Validators don't have access to each other and they don't need, however,
      # some validators might influence others, so their options should be shared
      def derive_validator_options(validations)
        allow_blank = validations[:allow_blank]

        {
          allow_blank: allow_blank.is_a?(Hash) ? allow_blank[:value] : allow_blank,
          fail_fast: validations.delete(:fail_fast) || false
        }
      end

      def validates_presence(validations, attrs, opts)
        return unless validations.key?(:presence) && validations[:presence]

        validate('presence', validations.delete(:presence), attrs, true, opts)
        validations.delete(:message) if validations.key?(:message)
      end
    end
  end
end
