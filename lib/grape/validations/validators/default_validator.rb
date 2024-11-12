# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class DefaultValidator < Base
        def initialize(attrs, options, required, scope, opts = {})
          @default = options
          super
        end

        def validate_param!(attr_name, params)
          params[attr_name] = if @default.is_a? Proc
                                if @default.parameters.empty?
                                  @default.call
                                else
                                  @default.call(params)
                                end
                              elsif @default.frozen? || !@default.duplicable?
                                @default
                              else
                                @default.dup
                              end
        end

        def validate!(params)
          attrs = SingleAttributeIterator.new(self, @scope, params)
          attrs.each do |resource_params, attr_name|
            next unless @scope.meets_dependency?(resource_params, params)

            validate_param!(attr_name, resource_params) if resource_params.is_a?(Hash) && resource_params[attr_name].nil?
          end
        end
      end
    end
  end
end
