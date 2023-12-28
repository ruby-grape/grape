# frozen_string_literal: true

module Grape
  class Router
    # this could be an OpenStruct, but doesn't work in Ruby 2.3.0, see https://bugs.ruby-lang.org/issues/12251
    # fixed >= 3.0
    class AttributeTranslator
      ROUTE_ATTRIBUTES = (%i[
        allow_header
        anchor
        endpoint
        format
        forward_match
        namespace
        not_allowed_method
        prefix
        request_method
        requirements
        settings
        suffix
        version
      ] | Grape::DSL::Desc::ROUTE_ATTRIBUTES).freeze

      def initialize(**attributes)
        @attributes = attributes
      end

      ROUTE_ATTRIBUTES.each do |attr|
        define_method attr do
          @attributes[attr]
        end

        define_method("#{attr}=") do |val|
          @attributes[attr] = val
        end
      end

      def to_h
        @attributes
      end

      def method_missing(method_name, *args)
        if setter?(method_name)
          @attributes[method_name.to_s.chomp('=').to_sym] = args.first
        else
          @attributes[method_name]
        end
      end

      def respond_to_missing?(method_name, _include_private = false)
        return true if setter?(method_name)

        @attributes.key?(method_name)
      end

      private

      def setter?(method_name)
        method_name.end_with?('=')
      end
    end
  end
end
