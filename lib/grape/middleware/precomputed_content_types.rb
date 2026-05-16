# frozen_string_literal: true

module Grape
  module Middleware
    # Include in a middleware subclass that needs content-type negotiation.
    # Provides +content_types+ / +mime_types+ / +content_type_for+ /
    # +content_type+ resolved from +options[:content_types]+ and
    # +options[:format]+, and warms those caches on the parent instance at
    # initialization so per-request +dup+s inherit them (avoiding
    # ~1 µs/request of +with_indifferent_access+ recomputation).
    #
    # Opt-in: plain +Grape::Middleware::Base+ subclasses that don't need
    # content-type-aware helpers don't pay for them.
    module PrecomputedContentTypes
      def initialize(app, **options)
        super
        content_types
        mime_types
        content_types_indifferent_access
      end

      def content_types
        @content_types ||= Grape::ContentTypes.content_types_for(options[:content_types])
      end

      def mime_types
        @mime_types ||= Grape::ContentTypes.mime_types_for(content_types)
      end

      def content_type_for(format)
        content_types_indifferent_access[format]
      end

      def content_type
        content_type_for(env[Grape::Env::API_FORMAT] || options[:format]) || 'text/html'
      end

      private

      def content_types_indifferent_access
        @content_types_indifferent_access ||= content_types.with_indifferent_access
      end
    end
  end
end
