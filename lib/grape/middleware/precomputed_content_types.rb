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
    # Opt-in: plain +Grape::Middleware::Base+ subclasses that don't need
    # content-type-aware helpers don't pay for them.
    module PrecomputedContentTypes
      def initialize(app, **options)
        super
        content_types
        mime_types
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

      # Every format under both spellings in one plain Hash, so a lookup is a
      # single +Hash#[]+. +HashWithIndifferentAccess+ converted the key on every
      # read instead, and this is read two or three times per request — to
      # negotiate the format, and again to set the response content type.
      #
      # Keys arrive as Symbols: the +content_type+ DSL symbolizes what it is
      # given and the defaults are Symbols. The key is stored as it came too,
      # so a middleware constructed directly with String keys still answers to
      # either spelling, as the indifferent hash did.
      def content_types_lookup
        @content_types_lookup ||= content_types.each_with_object({}) do |(format, media_type), lookup|
          lookup[format] = media_type
          lookup[format.is_a?(String) ? format.to_sym : format.to_s] = media_type
        end.freeze
      end
    end
  end
end
