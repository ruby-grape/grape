module Grape

  module Validations

    ##
    # All validators must inherit from this class.
    #
    class Validator
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
          if @required || resource_params.has_key?(attr_name)
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

      private

      def self.convert_to_short_name(klass)
        ret = klass.name.gsub(/::/, '/')
          .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
          .gsub(/([a-z\d])([A-Z])/, '\1_\2')
          .tr("-", "_")
          .downcase
        File.basename(ret, '_validator')
      end
    end

    ##
    # Base class for all validators taking only one param.
    class SingleOptionValidator < Validator
      def initialize(attrs, options, required, scope)
        @option = options
        super
      end

    end

    # We define Validator::inherited here so SingleOptionValidator
    # will not be considered a validator.
    class Validator
      def self.inherited(klass)
        short_name = convert_to_short_name(klass)
        Validations.register_validator(short_name, klass)
      end
    end

    class << self
      attr_accessor :validators
    end

    self.validators = {}

    def self.register_validator(short_name, klass)
      validators[short_name] = klass
    end

    class ParamsScope
      attr_accessor :element, :parent

      def initialize(opts, &block)
        @element  = opts[:element]
        @parent   = opts[:parent]
        @api      = opts[:api]
        @optional = opts[:optional] || false
        @declared_params = []

        instance_eval(&block)

        configure_declared_params
      end

      def should_validate?(parameters)
        return false if @optional && params(parameters).blank?
        return true if parent.nil?
        parent.should_validate?(parameters)
      end

      def requires(*attrs, &block)
        return new_scope(attrs, &block) if block_given?

        validations = { presence: true }
        validations.merge!(attrs.pop) if attrs.last.is_a?(Hash)

        push_declared_params(attrs)
        validates(attrs, validations)
      end

      def optional(*attrs, &block)
        return new_scope(attrs, true, &block) if block_given?

        validations = {}
        validations.merge!(attrs.pop) if attrs.last.is_a?(Hash)

        push_declared_params(attrs)
        validates(attrs, validations)
      end

      def group(element, &block)
        requires(element, &block)
      end

      def params(params)
        params = @parent.params(params) if @parent
        params = params[@element] || {} if @element
        params
      end

      def full_name(name)
        return "#{@parent.full_name(@element)}[#{name}]" if @parent
        name.to_s
      end

      protected

      def push_declared_params(attrs)
        @declared_params.concat attrs
      end

      private

      def new_scope(attrs, optional = false, &block)
        raise ArgumentError unless attrs.size == 1
        ParamsScope.new(api: @api, element: attrs.first, parent: self, optional: optional, &block)
      end

      # Pushes declared params to parent or settings
      def configure_declared_params
        if @parent
          @parent.push_declared_params [element => @declared_params]
        else
          @api.settings.peek[:declared_params] ||= []
          @api.settings[:declared_params].concat @declared_params
        end
      end

      def validates(attrs, validations)
        doc_attrs = { required: validations.keys.include?(:presence) }

        # special case (type = coerce)
        validations[:coerce] = validations.delete(:type) if validations.key?(:type)

        coerce_type = validations[:coerce]
        doc_attrs[:type] = coerce_type.to_s if coerce_type

        desc = validations.delete(:desc)
        doc_attrs[:desc] = desc if desc

        default = validations[:default]
        doc_attrs[:default] = default if default

        values = validations[:values]
        doc_attrs[:values] = values if values

        # default value should be present in values array, if both exist
        if default && values && !values.include?(default)
          raise Grape::Exceptions::IncompatibleOptionValues.new(:default, default, :values, values)
        end

        # type should be compatible with values array, if both exist
        if coerce_type && values && values.any? { |v| !v.instance_of?(coerce_type) }
          raise Grape::Exceptions::IncompatibleOptionValues.new(:type, coerce_type, :values, values)
        end

        full_attrs = attrs.collect { |name| { name: name, full_name: full_name(name) } }
        @api.document_attribute(full_attrs, doc_attrs)

        # Validate for presence before any other validators
        if validations.has_key?(:presence) && validations[:presence]
          validate('presence', validations[:presence], attrs, doc_attrs)
          validations.delete(:presence)
        end

        # Before we run the rest of the validators, lets handle
        # whatever coercion so that we are working with correctly
        # type casted values
        if validations.has_key? :coerce
          validate('coerce', validations[:coerce], attrs, doc_attrs)
          validations.delete(:coerce)
        end

        validations.each do |type, options|
          validate(type, options, attrs, doc_attrs)
        end
      end

      def validate(type, options, attrs, doc_attrs)
        validator_class = Validations.validators[type.to_s]

        if validator_class
          (@api.settings.peek[:validations] ||= []) << validator_class.new(attrs, options, doc_attrs[:required], self)
        else
          raise Grape::Exceptions::UnknownValidator.new(type)
        end
      end

    end

    # This module is mixed into the API Class.
    module ClassMethods
      def reset_validations!
        settings.peek[:declared_params] = []
        settings.peek[:validations] = []
      end

      def params(&block)
        ParamsScope.new(api: self, &block)
      end

      def document_attribute(names, opts)
        @last_description ||= {}
        @last_description[:params] ||= {}
        Array(names).each do |name|
          @last_description[:params][name[:full_name].to_s] ||= {}
          @last_description[:params][name[:full_name].to_s].merge!(opts)
        end
      end

    end

  end
end

# Load all defined validations.
Dir[File.expand_path('../validations/*.rb', __FILE__)].each do |path|
  require(path)
end
