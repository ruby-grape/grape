module Grape
  module Validations
    class ParamsScope
      attr_accessor :element, :parent

      include Grape::DSL::Parameters

      def initialize(opts, &block)
        @element  = opts[:element]
        @parent   = opts[:parent]
        @api      = opts[:api]
        @optional = opts[:optional] || false
        @type     = opts[:type]
        @declared_params = []

        instance_eval(&block) if block_given?

        configure_declared_params
      end

      def should_validate?(parameters)
        return false if @optional && params(parameters).respond_to?(:all?) && params(parameters).all?(&:blank?)
        return true if parent.nil?
        parent.should_validate?(parameters)
      end

      def full_name(name)
        return "#{@parent.full_name(@element)}[#{name}]" if @parent
        name.to_s
      end

      def root?
        !@parent
      end

      def required?
        !@optional
      end

      protected

      def push_declared_params(attrs)
        @declared_params.concat attrs
      end

      private

      def require_required_and_optional_fields(context, opts)
        if context == :all
          optional_fields = Array(opts[:except])
          required_fields = opts[:using].keys - optional_fields
        else # context == :none
          required_fields = Array(opts[:except])
          optional_fields = opts[:using].keys - required_fields
        end
        required_fields.each do |field|
          field_opts = opts[:using][field]
          fail ArgumentError, "required field not exist: #{field}" unless field_opts
          requires(field, field_opts)
        end
        optional_fields.each do |field|
          field_opts = opts[:using][field]
          optional(field, field_opts) if field_opts
        end
      end

      def require_optional_fields(context, opts)
        optional_fields = opts[:using].keys
        optional_fields -= Array(opts[:except]) unless context == :all
        optional_fields.each do |field|
          field_opts = opts[:using][field]
          optional(field, field_opts) if field_opts
        end
      end

      def validate_attributes(attrs, opts, &block)
        validations = opts.clone
        validations[:type] ||= Array if block
        validates(attrs, validations)
      end

      def new_scope(attrs, optional = false, &block)
        # if required params are grouped and no type or unsupported type is provided, raise an error
        type = attrs[1] ? attrs[1][:type] : nil
        if attrs.first && !optional
          fail Grape::Exceptions::MissingGroupTypeError.new if type.nil?
          fail Grape::Exceptions::UnsupportedGroupTypeError.new unless [Array, Hash].include?(type)
        end

        opts = attrs[1] || { type: Array }
        ParamsScope.new(api: @api, element: attrs.first, parent: self, optional: optional, type: opts[:type], &block)
      end

      # Pushes declared params to parent or settings
      def configure_declared_params
        if @parent
          @parent.push_declared_params [element => @declared_params]
        else
          @api.namespace_stackable(:declared_params, @declared_params)

          @api.route_setting(:declared_params, []) unless @api.route_setting(:declared_params)
          @api.route_setting(:declared_params).concat @declared_params
        end
      end

      def validates(attrs, validations)
        doc_attrs = { required: validations.keys.include?(:presence) }

        # special case (type = coerce)
        validations[:coerce] = validations.delete(:type) if validations.key?(:type)

        coerce_type = validations[:coerce]

        doc_attrs[:type] = coerce_type.to_s if coerce_type

        desc = validations.delete(:desc) || validations.delete(:description)
        doc_attrs[:desc] = desc if desc

        default = validations[:default]
        doc_attrs[:default] = default if validations.key?(:default)

        values = validations[:values]
        doc_attrs[:values] = values if values

        coerce_type = guess_coerce_type(coerce_type, values)

        # default value should be present in values array, if both exist and are not procs
        check_incompatible_option_values(values, default)

        # type should be compatible with values array, if both exist
        validate_value_coercion(coerce_type, values)

        doc_attrs[:documentation] = validations.delete(:documentation) if validations.key?(:documentation)

        full_attrs = attrs.collect { |name| { name: name, full_name: full_name(name) } }
        @api.document_attribute(full_attrs, doc_attrs)

        # Validate for presence before any other validators
        if validations.key?(:presence) && validations[:presence]
          validate('presence', validations[:presence], attrs, doc_attrs)
          validations.delete(:presence)
        end

        # Before we run the rest of the validators, lets handle
        # whatever coercion so that we are working with correctly
        # type casted values
        if validations.key? :coerce
          validate('coerce', validations[:coerce], attrs, doc_attrs)
          validations.delete(:coerce)
        end

        validations.each do |type, options|
          validate(type, options, attrs, doc_attrs)
        end
      end

      def guess_coerce_type(coerce_type, values)
        return coerce_type if !values || values.is_a?(Proc)
        return values.first.class if coerce_type == Array && (values.is_a?(Range) || !values.empty?)
        coerce_type
      end

      def check_incompatible_option_values(values, default)
        return unless values && default
        return if values.is_a?(Proc) || default.is_a?(Proc)
        return if values.include?(default)
        fail Grape::Exceptions::IncompatibleOptionValues.new(:default, default, :values, values)
      end

      def validate(type, options, attrs, doc_attrs)
        validator_class = Validations.validators[type.to_s]

        if validator_class
          value = validator_class.new(attrs, options, doc_attrs[:required], self)
          @api.namespace_stackable(:validations, value)
        else
          fail Grape::Exceptions::UnknownValidator.new(type)
        end
      end

      def validate_value_coercion(coerce_type, values)
        return unless coerce_type && values
        return if values.is_a?(Proc)
        coerce_type = coerce_type.first if coerce_type.is_a?(Array)
        value_types = values.is_a?(Range) ? [values.begin, values.end] : values
        if value_types.any? { |v| !v.is_a?(coerce_type) }
          fail Grape::Exceptions::IncompatibleOptionValues.new(:type, coerce_type, :values, values)
        end
      end
    end
  end
end
