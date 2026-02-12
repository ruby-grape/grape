# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class DefaultValidator < Base
        def initialize(attrs, options, required, scope, opts)
          super
          # !important, lazy call at runtime
          @default_call =
            if @option.is_a?(Proc)
              @option.arity.zero? ? ->(_p) { @option.call } : ->(p) { @option.call(p) }
            elsif @option.frozen? || !@option.duplicable?
              ->(_p) { @option }
            else
              ->(_p) { @option.dup }
            end
        end

        def validate!(params)
          attrs = SingleAttributeIterator.new(@attrs, @scope, params)
          attrs.each do |resource_params, attr_name|
            next unless @scope.meets_dependency?(resource_params, params)

            resource_params[attr_name] = @default_call.call(resource_params) if resource_params.is_a?(Hash) && resource_params[attr_name].nil?
          end
        end
      end
    end
  end
end
