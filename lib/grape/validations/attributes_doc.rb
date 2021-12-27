# frozen_string_literal: true

module Grape
  module Validations
    class ParamsScope
      # Documents parameters of an endpoint. If documentation isn't needed (for instance, it is an
      # internal API), the class only cleans up attributes to avoid junk in RAM.
      class AttributesDoc
        attr_accessor :type, :values

        # @param api [Grape::API::Instance]
        # @param scope [Validations::ParamsScope]
        def initialize(api, scope)
          @api = api
          @scope = scope
          @type = type
        end

        def extract_details(validations)
          details[:required] = validations.key?(:presence)

          desc = validations.delete(:desc) || validations.delete(:description)

          details[:desc] = desc if desc

          documentation = validations.delete(:documentation)

          details[:documentation] = documentation if documentation

          details[:default] = validations[:default] if validations.key?(:default)
        end

        def document(attrs)
          return if @api.namespace_inheritable(:do_not_document)

          details[:type] = type.to_s if type
          details[:values] = values if values

          documented_attrs = attrs.each_with_object({}) do |name, memo|
            memo[@scope.full_name(name)] = details
          end

          @api.namespace_stackable(:params, documented_attrs)
        end

        def required
          details[:required]
        end

        protected

        def details
          @details ||= {}
        end
      end
    end
  end
end
