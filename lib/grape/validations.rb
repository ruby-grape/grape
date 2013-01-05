require 'virtus'

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
          raise "unknown options: #{options.keys}"
        end
      end

      def validate!(params)
        params = @scope.params(params)

        @attrs.each do |attr_name|
          if @required || params.has_key?(attr_name)
            validate_param!(attr_name, params)
          end
        end
      end

    private

      def self.convert_to_short_name(klass)
        ret = klass.name.gsub(/::/, '/').
          gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
          gsub(/([a-z\d])([A-Z])/,'\1_\2').
          tr("-", "_").
          downcase
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
        Validations::register_validator(short_name, klass)
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

      def initialize(api, element, parent, &block)
        @element = element
        @parent = parent
        @api = api
        instance_eval(&block)
      end
      
      def requires(*attrs)
        validations = {:presence => true}
        if attrs.last.is_a?(Hash)
          validations.merge!(attrs.pop)
        end
        
        push_declared_params(attrs)
        validates(attrs, validations)
      end
      
      def optional(*attrs)
        validations = {}
        if attrs.last.is_a?(Hash)
          validations.merge!(attrs.pop)
        end

        push_declared_params(attrs)
        validates(attrs, validations)
      end

      def group(element, &block)
        ParamsScope.new(@api, element, self, &block)
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

    private
      def validates(attrs, validations)
        doc_attrs = { :required => validations.keys.include?(:presence) }
        
        # special case (type = coerce)
        if validations[:type]
          validations[:coerce] = validations.delete(:type)
        end
        
        if coerce_type = validations[:coerce]
          doc_attrs[:type] = coerce_type.to_s
        end
        
        if desc = validations.delete(:desc)
          doc_attrs[:desc] = desc
        end

        full_attrs = attrs.collect{ |name| { :name => name, :full_name => full_name(name)} }
        @api.document_attribute(full_attrs, doc_attrs)

        # Validate for presence before any other validators
        if validations.has_key?(:presence) && validations[:presence]
          validate('presence', validations[:presence], attrs, doc_attrs)
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
        validator_class = Validations::validators[type.to_s]

        if validator_class
          (@api.settings.peek[:validations] ||= []) << validator_class.new(attrs, options, doc_attrs[:required], self)
        else
          raise "unknown validator: #{type}"
        end
      end

      def push_declared_params(attrs)
        @api.settings.peek[:declared_params] ||= []
        @api.settings[:declared_params] += attrs
      end
    end
    
    # This module is mixed into the API Class.
    module ClassMethods
      def reset_validations!
        settings.peek[:declared_params] = []
        settings.peek[:validations] = []
      end
      
      def params(&block)
        ParamsScope.new(self, nil, nil, &block)
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
