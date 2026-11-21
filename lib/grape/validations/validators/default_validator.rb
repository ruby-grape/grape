# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class DefaultValidator < Base
        # What answers a missing param's default. Frozen objects rather than
        # procs: a proc carries the validator as its self and the values it
        # closes over as they are, so a compiled API holding one could not be
        # frozen all the way down.
        Value = Data.define(:value) do
          def call(_params) = value
        end

        Copy = Data.define(:value) do
          def call(_params) = value.dup
        end

        Deferred = Data.define(:callable) do
          def call(_params) = callable.call
        end
        private_constant :Value, :Copy, :Deferred

        def initialize(attrs, options, required, scope, opts)
          super
          # !important, lazy call at runtime
          @default_call =
            if options.is_a?(Proc)
              options.arity.zero? ? Deferred.new(options) : options
            elsif options.duplicable?
              Copy.new(options)
            else
              Value.new(options)
            end
        end

        def validate!(params)
          scoped = scope.params(params) if @direct
          return apply_defaults(scoped) if scoped.is_a?(Hash)

          @iterator.each(params) do |resource_params|
            next unless scope.meets_dependency?(resource_params, params)

            apply_defaults(resource_params) if hash_like?(resource_params)
          end
        end

        private

        # Also #validate!'s whole job where Base#validate_attributes! applies:
        # a scope with no Array scope and no +given+ on its chain, once its
        # params resolved to a Hash -- the root scope of every +params+ block
        # with a default in it, and the Hash scopes under it. A scope like
        # that depends on no other param, so the iterator and its dependency
        # check have nothing to add.
        def apply_defaults(params)
          @attrs.each do |attr_name|
            params[attr_name] = @default_call.call(params) if params[attr_name].nil?
          end
        end
      end
    end
  end
end
