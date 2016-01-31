require 'delegate'
require 'ostruct'

module Grape
  class Router
    class AttributeTranslator < DelegateClass(OpenStruct)
      def self.register(*attributes)
        AttributeTranslator.supported_attributes.concat(attributes)
      end

      def self.supported_attributes
        @supported_attributes ||= []
      end

      def initialize(attributes = {})
        ostruct = OpenStruct.new(attributes)
        super ostruct
        @attributes = attributes
        self.class.supported_attributes.each do |name|
          ostruct.send(:"#{name}=", nil) unless ostruct.respond_to?(name)
          self.class.instance_eval do
            define_method(name) { instance_variable_get(:"@#{name}") }
          end if name == :format
        end
      end

      def to_h
        @attributes.each_with_object({}) do |(key, _), attributes|
          attributes[key.to_sym] = send(:"#{key}")
        end
      end

      private

      def accessor_available?(name)
        respond_to?(name) && respond_to?(:"#{name}=")
      end
    end
  end
end
