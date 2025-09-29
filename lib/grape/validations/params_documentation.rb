# frozen_string_literal: true

module Grape
  module Validations
    # Documents parameters of an endpoint. If documentation isn't needed (for instance, it is an
    # internal API), the class only cleans up attributes to avoid junk in RAM.

    module ParamsDocumentation
      def document_params(attrs, validations, type = nil, values = nil, except_values = nil)
        return validations.except!(:desc, :description, :documentation) if @api.inheritable_setting.namespace_inheritable[:do_not_document]

        documented_attrs = attrs.each_with_object({}) do |name, memo|
          memo[full_name(name)] = extract_details(validations, type, values, except_values)
        end
        @api.inheritable_setting.namespace_stackable[:params] = documented_attrs
      end

      private

      def extract_details(validations, type, values, except_values)
        {}.tap do |details|
          details[:required] = validations.key?(:presence)
          details[:type] = TypeCache[type] if type
          details[:values] = values if values
          details[:except_values] = except_values if except_values
          details[:default] = validations[:default] if validations.key?(:default)
          if validations.key?(:length)
            details[:min_length] = validations[:length][:min] if validations[:length].key?(:min)
            details[:max_length] = validations[:length][:max] if validations[:length].key?(:max)
          end

          desc = validations.delete(:desc) || validations.delete(:description)
          details[:desc] = desc if desc

          documentation = validations.delete(:documentation)
          details[:documentation] = documentation if documentation
        end
      end

      class TypeCache < Grape::Util::Cache
        def initialize
          super
          @cache = Hash.new do |h, type|
            h[type] = type.to_s
          end
        end
      end
    end
  end
end
