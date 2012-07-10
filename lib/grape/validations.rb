require 'virtus'
Boolean = Virtus::Attribute::Boolean
module Grape
  
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
  end
  
  
  class SingleOptionValidator < Validator
    def initialize(attrs, options)
      @option = options
      super
    end
    
  end
  
  
  class PresenceValidator < Validator
    def validate_param!(attr_name, params)
      unless params.has_key?(attr_name)
        throw :error, :status => 400, :message => "missing parameter: #{attr_name}"
      end
    end
    
  end
  
  class CoerceValidator < SingleOptionValidator
    def validate_param!(attr_name, params)
      params[attr_name] = coerce_value(@option, params[attr_name])
    end
  
  private
    def coerce_value(type, val)
      converter = Virtus::Attribute.build(:a, type)
      converter.coerce(val)
    end
  end
  
  class RegExpValidator < SingleOptionValidator
    def validate_param!(attr_name, params)
      if params[attr_name] && !( params[attr_name].to_s =~ @option )
        throw :error, :status => 400, :message => "invalid parameter: #{attr_name}"
      end
    end
  end
    
  
  
  module Validations
    
    class <<self
      attr_accessor :validators
    end
    
    self.validators = {}
    self.validators[:presence] = PresenceValidator
    self.validators[:regexp] = RegExpValidator
    self.validators[:coerce] = CoerceValidator
    
    def self.included(klass)
      klass.instance_eval do
        extend ClassMethods
      end
    end
    
    module ClassMethods
      def reset_validations!
        settings[:validations] = []
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
      
      def validates(attrs, validations)
        doc_attrs = { :required => validations.keys.include?(:presence) }
        
        if coerce_type = validations[:coerce]
          doc_attrs[:type] = coerce_type.to_s
        end
        
        if desc = validations.delete(:desc)
          doc_attrs[:desc] = desc
        end
        
        document_attribute(attrs, doc_attrs)
        
        validations.each do |type, options|
          validator_class = Validations::validators[type]
          if validator_class
            settings[:validations] << validator_class.new(attrs, options)
          else
            raise "unknown validator: #{type}"
          end
        end
        
      end

      
    end
    
  end
end
