# frozen_string_literal: true

module Grape
  module Validations
    class AttributesIterator
      include Enumerable

      attr_reader :scope

      def initialize(attrs, scope, params)
        @attrs = attrs
        @scope = scope
        @original_params = scope.params(params)
        @params = Array.wrap(@original_params)
      end

      def each(&)
        do_each(@params, &) # because we need recursion for nested arrays
      end

      private

      def do_each(params_to_process, parent_indices = [], &block)
        params_to_process.each_with_index do |resource_params, index|
          # when we get arrays of arrays it means that target element located inside array
          # we need this because we want to know parent arrays indices
          if resource_params.is_a?(Array)
            do_each(resource_params, [index] + parent_indices, &block)
            next
          end

          if @scope.type == Array
            next unless @original_params.is_a?(Array) # do not validate content of array if it isn't array

            store_indices(@scope, index, parent_indices)
          elsif @original_params.is_a?(Array)
            # Lateral scope (no @element) whose params resolved to an array —
            # delegate index tracking to the nearest array-typed ancestor so
            # that full_name produces the correct bracketed index.
            target = @scope.nearest_array_ancestor
            store_indices(target, index, parent_indices) if target
          end

          yield_attributes(resource_params, &block)
        end
      end

      def store_indices(target_scope, index, parent_indices)
        # No tracker means we're outside a ParamScopeTracker.track block (e.g.
        # a unit test that invokes a validator directly). Index tracking is
        # skipped — full_name will produce bracket-less names — but validation
        # continues rather than crashing.
        tracker = ParamScopeTracker.current or return
        parent_scope = target_scope.parent
        parent_indices.each do |parent_index|
          break unless parent_scope

          tracker.store_index(parent_scope, parent_index)
          parent_scope = parent_scope.parent
        end
        tracker.store_index(target_scope, index)
      end

      def yield_attributes(_resource_params)
        raise NotImplementedError
      end

      # This is a special case so that we can ignore trees where option
      # values are missing lower down. Unfortunately we can't remove this
      # at the parameter parsing stage as they are required to ensure
      # the correct indexing is maintained
      def skip?(val)
        val == Grape::DSL::Parameters::EmptyOptionalValue
      end
    end
  end
end
