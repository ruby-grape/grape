# frozen_string_literal: true

module Grape
  module Validations
    class AttributesIterator
      # +attrs+ and +scope+ are static per validator; only +params+ varies
      # per request, so an instance can be built once and reused (it keeps
      # no request-derived state). Reused instances are shared across
      # threads, so +each+ must stay free of mutable instance state.
      def initialize(attrs, scope)
        @attrs = attrs
        @scope = scope
        # How many times #do_each may descend into a nested array. The
        # declaration allows one level per Array-typed scope on the chain, less
        # the one +Array.wrap+ already consumes in #each. Anything deeper was
        # put there by the request, not by the declaration.
        @max_nesting = [scope.array_depth - 1, 0].max
      end

      def each(params, &)
        original_params = @scope.params(params)
        # A scope resolves to a Hash unless the declaration nests arrays, and
        # then #do_each has nothing to do but hand it straight back: Array.wrap
        # boxes it, the loop unboxes it on its only iteration, and with no Array
        # anywhere neither the nesting descent nor the index bookkeeping
        # applies. Every validator on a flat +params+ block comes through here.
        return yield_attributes(original_params, &) if original_params.is_a?(Hash) && !@scope.iterates_elements?

        # because we need recursion for nested arrays
        do_each(Array.wrap(original_params), original_params, &)
      end

      private

      def do_each(params_to_process, original_params, parent_indices = [], &block)
        params_to_process.each_with_index do |resource_params, index|
          # when we get arrays of arrays it means that target element located inside array
          # we need this because we want to know parent arrays indices
          #
          # Only descend as far as the declaration nests. A request that wraps
          # its elements deeper than that is yielded as-is, so the attribute
          # validators see a non-hash and fail it the same way any other
          # unexpected element type does.
          if resource_params.is_a?(Array) && parent_indices.size < @max_nesting
            do_each(resource_params, original_params, [index] + parent_indices, &block)
            next
          end

          if @scope.iterates_elements?
            next unless original_params.is_a?(Array) # do not validate content of array if it isn't array

            store_indices(@scope, index, parent_indices)
          elsif original_params.is_a?(Array)
            # Lateral scope (no @element) whose params resolved to an array —
            # delegate index tracking to the nearest element-iterating ancestor
            # so that full_name produces the correct bracketed index.
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
