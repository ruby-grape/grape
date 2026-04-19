# frozen_string_literal: true

module Grape
  module Middleware
    # Include in a middleware subclass to warm the content-type caches on the
    # parent instance at initialization. Per-request dups inherit the cached
    # values via +dup+'s ivar copy, avoiding ~1 µs per request of
    # +with_indifferent_access+ recomputation.
    #
    # Opt-in: plain +Grape::Middleware::Base+ subclasses continue to compute
    # +content_types+ / +mime_types+ / +content_type_for+ lazily on first
    # access.
    module PrecomputedContentTypes
      def initialize(app, **options)
        super
        content_types
        mime_types
        content_types_indifferent_access
      end
    end
  end
end
