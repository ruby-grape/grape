# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class DefaultValidator < Base
        def initialize(attrs, options, required, scope, opts)
          super
          # !important, lazy call at runtime
          @default_call =
            if options.is_a?(Proc)
              options.arity.zero? ? proc { options.call } : options
            elsif options.duplicable?
              proc { options.dup }
            else
              proc { options }
            end
        end

        def validate!(params)
          scoped = scope.params(params) if @direct
          return apply_defaults(scoped) if scoped.is_a?(Hash)

          @iterator.each(params) do |resource_params, attr_name|
            next unless scope.meets_dependency?(resource_params, params)

            resource_params[attr_name] = @default_call.call(resource_params) if hash_like?(resource_params) && resource_params[attr_name].nil?
          end
        end

        private

        # #validate! where Base#validate_attributes! applies: a scope that is
        # always validated and does not iterate elements, once its params
        # resolved to a Hash -- the root scope of every +params+ block with a
        # default in it. The iterator would hand that Hash back once per
        # attribute, and a scope like that depends on no other param, so all
        # that is left of its checks is whether the value is missing.
        def apply_defaults(params)
          @attrs.each do |attr_name|
            params[attr_name] = @default_call.call(params) if params[attr_name].nil?
          end
        end
      end
    end
  end
end
