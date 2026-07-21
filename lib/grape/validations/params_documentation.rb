# frozen_string_literal: true

module Grape
  module Validations
    # Documents parameters of an endpoint. Reads from a frozen
    # +ValidationsSpec+; never mutates the user's validations hash.
    module ParamsDocumentation
      def document_params(attrs, spec)
        return if @api.inheritable_setting.do_not_document?

        documented_attrs = attrs.to_h do |name|
          [full_name(name), extract_details(spec)]
        end
        @api.inheritable_setting.add_params_documentation(documented_attrs)
      end

      private

      def extract_details(spec)
        details = {}
        details[:required] = spec.required?
        details[:type] = TypeCache[spec.coerce_type] if spec.coerce_type
        details[:values] = spec.values if spec.values
        details[:except_values] = spec.except_values if spec.except_values
        details[:default] = spec.default unless spec.default.nil?

        length = spec.raw[:length]
        if length.is_a?(Hash)
          details[:min_length] = length[:min] if length.key?(:min)
          details[:max_length] = length[:max] if length.key?(:max)
        end

        desc = spec.raw[:desc] || spec.raw[:description]
        details[:desc] = desc if desc

        documentation = spec.raw[:documentation]
        details[:documentation] = documentation if documentation

        details
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
