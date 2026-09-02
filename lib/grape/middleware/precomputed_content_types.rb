# frozen_string_literal: true

module Grape
  module Middleware
    # Include in a middleware subclass that needs content-type negotiation.
    # Provides +content_types+ / +mime_types+ / +content_type_for+ /
    # +content_type+ resolved from +config.content_types+ and
    # +config.format+ — so the consuming middleware's +Options+ Data class
    # must declare both fields. Warms those caches on the parent instance
    # at initialization so per-request +dup+s inherit them rather than
    # rebuilding them.
    #
    # +mime_types+ is not warmed here: Formatter is the only middleware that
    # reads it, and it warms it itself. The tables behind +mime_types+ and
    # +content_type_for+ are shared process-wide per content-type registry
    # (see Grape::ContentTypes), so the ivars below memoize a lookup, not a
    # copy.
    #
    # Opt-in: plain +Grape::Middleware::Base+ subclasses that don't need
    # content-type-aware helpers don't pay for them.
    module PrecomputedContentTypes
      def initialize(app, **options)
        super
        content_types
        content_types_lookup
      end

      def content_types
        @content_types ||= Grape::ContentTypes.content_types_for(config.content_types)
      end

      def mime_types
        @mime_types ||= Grape::ContentTypes.mime_types_for(content_types)
      end

      def content_type_for(format)
        content_types_lookup[format]
      end

      def content_type
        content_type_for(env[Grape::Env::API_FORMAT] || config.format) || 'text/html'
      end

      private

      def content_types_lookup
        @content_types_lookup ||= Grape::ContentTypes.lookup_for(content_types)
      end
    end
  end
end
