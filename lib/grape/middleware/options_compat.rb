# frozen_string_literal: true

module Grape
  module Middleware
    # Mixin for per-middleware `Options` Data classes.
    #
    # Provides a Hash-like `[](key)` reader so the legacy `options[:key]`
    # idiom in `Grape::Middleware::Base` (notably `#content_types` and
    # `#content_type`) keeps working when a subclass swaps its Hash
    # `DEFAULT_OPTIONS` for a `Data.define(...)`-backed `Options` class.
    # Unknown keys return +nil+ to match the old behaviour.
    module OptionsCompat
      def [](key)
        return nil unless respond_to?(key)

        public_send(key)
      end
    end
  end
end
