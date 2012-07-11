require 'virtus'
Boolean = Virtus::Attribute::Boolean

module Grape
    
  module Validations
    
    ##
    # All validators must inherit from this class.
    # 
    class Validator
      def initialize(attrs, options)
        @attrs = Array(attrs)

        if options.is_a?(Hash) && !options.empty?
          raise "unknown options: #{options.keys}"
        end
      end

      def validate!(params)
        @attrs.each do |attr_name|
          validate_param!(attr_name, params)
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
      def initialize(attrs, options)
        @option = options
        super
      end

    end

    # we define Validator::inherited here so SingleOptionValidator
    # will not be considered a validator.
    class Validator
      def self.inherited(klass)
        short_name = convert_to_short_name(klass)
        Validations::register_validator(short_name, klass)
      end
    end
    
    
    
    class <<self
      attr_accessor :validators
    end
    
    self.validators = {}
    
    def self.register_validator(short_name, klass)
      validators[short_name] = klass
    end
    
    
    class ParamsScope
      def initialize(api, &block)
        @api = api
        instance_eval(&block)
      end
      
      def requires(*attrs)
        validations = {:presence => true}
        if attrs.last.is_a?(Hash)
          validations.merge!(attrs.pop)
        end
        
        validates(attrs, validations)
      end
      
      def optional(*attrs)
        validations = {}
        if attrs.last.is_a?(Hash)
          validations.merge!(attrs.pop)
        end
        
        validates(attrs, validations)
      end
      
    private
      def validates(attrs, validations)
        doc_attrs = { :required => validations.keys.include?(:presence) }
        
        if coerce_type = validations[:coerce]
          doc_attrs[:type] = coerce_type.to_s
        end
        
        if desc = validations.delete(:desc)
          doc_attrs[:desc] = desc
        end
        
        @api.document_attribute(attrs, doc_attrs)
        
        validations.each do |type, options|
          validator_class = Validations::validators[type.to_s]
          if validator_class
            @api.settings[:validations] << validator_class.new(attrs, options)
          else
            raise "unknown validator: #{type}"
          end
        end
      
      end
      
    end
    
    # This module is mixed into the API Class.
    module ClassMethods
      def reset_validations!
        settings[:validations] = []
      end
      
      def params(&block)
        ParamsScope.new(self, &block)
      end
      
      def document_attribute(names, opts)
        if @last_description
          @last_description[:params] ||= {}
        
          Array(names).each do |name|
            @last_description[:params][name.to_sym] ||= {}
            @last_description[:params][name.to_sym].merge!(opts)
          end
        end
      end
      
    end
    
  end
end

# load all defined validations
Dir[File.expand_path('../validations/*.rb', __FILE__)].each do |path|
  require(path)
end
