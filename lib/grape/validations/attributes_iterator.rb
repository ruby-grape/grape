# frozen_string_literal: true

module Grape
  module Validations
    # Yields each value a scope's attributes are read from: the scope's params,
    # or each element of them when the scope sits in an Array. Walking the
    # attributes themselves is left to the validator's block.
    #
    # Each value comes with whether it is an element a request sent in the
    # scope's own Array. Otherwise it is the scope's value in an element of an
    # Array further up, where an empty one is an optional scope left out of
    # that element, or an element of an optional scope's Array whose elements
    # are all empty, which is passed over the same way.
    class AttributesIterator
      # +scope+ is static per validator; only +params+ varies per request, so
      # an instance can be built once and reused (it keeps no request-derived
      # state). Reused instances are shared across threads, so +each+ must
      # stay free of mutable instance state.
      def initialize(scope)
        @scope = scope
        # How many times #do_each may descend into a nested array. The
        # declaration allows one level per Array-typed scope on the chain, less
        # the one +Array.wrap+ already consumes in #each. Anything deeper was
        # put there by the request, not by the declaration.
        @max_nesting = [scope.array_depth - 1, 0].max
        @iterates_elements = scope.iterates_elements?
        @optional = !scope.required?
      end

      def each(params, &)
        original_params = @scope.params(params)
        iterates_elements = @scope.iterates_elements?
        # A scope resolves to a Hash unless the declaration nests arrays, and
        # then #do_each has nothing to do but hand it straight back: Array.wrap
        # boxes it, the loop unboxes it on its only iteration, and with no Array
        # anywhere neither the nesting descent nor the index bookkeeping
        # applies. Every validator on a flat +params+ block comes through here.
        return yield(original_params) if original_params.is_a?(Hash) && !iterates_elements

        array_params = original_params.is_a?(Array)
        # Do not validate the content of an array scope that did not get one.
        return if iterates_elements && !array_params

        # Where each element's index is recorded depends on the scope and on
        # whether its params are an Array, never on the element, so it is
        # settled once here rather than per element. A lateral scope (no
        # @element) whose params resolved to an array hands its index to the
        # nearest element-iterating ancestor, so full_name still produces the
        # right bracketed index.
        index_scope = iterates_elements ? @scope : (@scope.nearest_array_ancestor if array_params)
        # No tracker means we're outside a ParamScopeTracker.track block (e.g.
        # a unit test that invokes a validator directly). Index tracking is
        # skipped — full_name will produce bracket-less names — but validation
        # continues rather than crashing.
        tracker = ParamScopeTracker.current if index_scope

        # because we need recursion for nested arrays
        params_to_process = Array.wrap(original_params)
        do_each(params_to_process, tracker, index_scope, NO_PARENT_INDICES, sent_elements?(params_to_process, NO_PARENT_INDICES), &)
      end

      private

      # The top-level call's parent indices; only ever read.
      NO_PARENT_INDICES = [].freeze
      private_constant :NO_PARENT_INDICES

      def do_each(params_to_process, tracker, index_scope, parent_indices, sent_elements, &)
        params_to_process.each_with_index do |resource_params, index|
          # when we get arrays of arrays it means that target element located inside array
          # we need this because we want to know parent arrays indices
          #
          # Only descend as far as the declaration nests. A request that wraps
          # its elements deeper than that is yielded as-is, so the attribute
          # validators see a non-hash and fail it the same way any other
          # unexpected element type does.
          if resource_params.is_a?(Array) && parent_indices.size < @max_nesting
            nested_indices = [index] + parent_indices
            do_each(resource_params, tracker, index_scope, nested_indices, sent_elements?(resource_params, nested_indices), &)
            next
          end

          store_indices(tracker, index_scope, index, parent_indices) if tracker
          yield resource_params, sent_elements unless skip?(resource_params)
        end
      end

      # Whether +values+, reached through +parent_indices+, are elements of the
      # scope's own Array that were sent. An optional scope's Array whose
      # elements are all empty is passed over, as the scope itself is when it
      # is left out (see ParamsScope#should_validate?, which answers that for
      # the Array at the root). Checked once per Array rather than per element.
      def sent_elements?(values, parent_indices)
        @iterates_elements && parent_indices.size == @max_nesting && !(@optional && values.all? { |value| empty?(value) })
      end

      # Primitives like Integers and Booleans don't respond to +empty?+.
      def empty?(value)
        value.respond_to?(:empty?) ? value.empty? : value.nil?
      end

      # Each parent index belongs to the next element-iterating scope up the
      # chain, which a Hash scope may sit below. There is always one:
      # +parent_indices+ holds at most +array_depth - 1+ entries, and
      # +target_scope+ has that many iterating ancestors.
      def store_indices(tracker, target_scope, index, parent_indices)
        parent_scope = target_scope.nearest_array_ancestor
        parent_indices.each do |parent_index|
          tracker.store_index(parent_scope, parent_index)
          parent_scope = parent_scope.nearest_array_ancestor
        end
        tracker.store_index(target_scope, index)
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
