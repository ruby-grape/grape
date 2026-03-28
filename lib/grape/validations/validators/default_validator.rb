# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class DefaultValidator < Base
        def initialize(attrs, options, required, scope, opts)
          super
          # !important, lazy call at runtime
          @default_call =
            if @options.is_a?(Proc)
              @options.arity.zero? ? proc { @options.call } : @options
            elsif @options.duplicable?
              proc { @options.dup }
            else
              proc { @options }
            end
        end

        def validate!(params)
          attrs = SingleAttributeIterator.new(@attrs, @scope, params)
          attrs.each do |resource_params, attr_name|
            next unless @scope.meets_dependency?(resource_params, params)

            resource_params[attr_name] = @default_call.call(resource_params) if hash_like?(resource_params) && resource_params[attr_name].nil?
          end
        end
      end
    end
  end
end
