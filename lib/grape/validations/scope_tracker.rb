# frozen_string_literal: true

module Grape
  module Validations
    # Holds per-request mutable state that must not live on shared ParamsScope
    # instances. Both trackers are identity-keyed hashes so that ParamsScope
    # objects can serve as keys without relying on value equality.
    #
    # Lifecycle is managed by Endpoint#run_validators via +.track+.
    # Use +.current+ to access the instance for the running request.
    class ScopeTracker
      FIBER_KEY = :grape_scope_tracker
      EMPTY_PARAMS = [].freeze

      def self.track
        previous = Fiber[FIBER_KEY]
        Fiber[FIBER_KEY] = new
        yield
      ensure
        Fiber[FIBER_KEY] = previous
      end

      def self.current
        Fiber[FIBER_KEY]
      end

      def initialize
        @index_tracker = {}.compare_by_identity
        @dependency_tracker = {}.compare_by_identity
      end

      def store_index(scope, index)
        @index_tracker.store(scope, index)
      end

      def index_for(scope)
        @index_tracker[scope]
      end

      # Returns qualifying params for +scope+, or EMPTY_PARAMS if none were stored.
      # Note: an explicitly stored empty array and "never stored" are treated identically
      # by callers (both yield a blank result that falls through to the parent params).
      def qualifying_params(scope)
        @dependency_tracker.fetch(scope, EMPTY_PARAMS)
      end

      def store_qualifying_params(scope, params)
        @dependency_tracker.store(scope, params)
      end
    end
  end
end
