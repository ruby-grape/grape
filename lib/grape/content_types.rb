# frozen_string_literal: true

module Grape
  module ContentTypes
    module_function

    # Content types are listed in order of preference.
    DEFAULTS = {
      xml: 'application/xml',
      serializable_hash: 'application/json',
      json: 'application/json',
      binary: 'application/octet-stream',
      txt: 'text/plain'
    }.freeze

    MIME_TYPES = Grape::ContentTypes::DEFAULTS.except(:serializable_hash).invert.freeze

    def content_types_for(from_settings)
      from_settings.presence || DEFAULTS
    end

    def mime_types_for(from_settings)
      return MIME_TYPES if from_settings == Grape::ContentTypes::DEFAULTS

      MimeTypesCache[from_settings]
    end

    # Every format under both spellings in one plain Hash, so a lookup is a
    # single +Hash#[]+. +HashWithIndifferentAccess+ converted the key on every
    # read instead, and this is read two or three times per request — to
    # negotiate the format, and again to set the response content type.
    #
    # Keys arrive as Symbols: the +content_type+ DSL symbolizes what it is
    # given and the defaults are Symbols. The key is stored as it came too,
    # so a middleware constructed directly with String keys still answers to
    # either spelling, as the indifferent hash did.
    def lookup_for(from_settings)
      LookupCache[from_settings]
    end

    # The media type of a content-type header: the part before any `;`
    # parameters, with surrounding whitespace removed
    # (e.g. `'text/html'` for `'text/html; charset=utf-8'`). Returns nil for a
    # nil content type. Skips the split (and its allocation) when there are no
    # parameters, which is the common case.
    def media_type(content_type)
      return if content_type.nil?

      base = content_type.include?(';') ? content_type.split(';', 2).first : content_type
      base.strip
    end

    # Both tables below are derived from nothing but the content-type registry,
    # and one content-type-aware middleware is built per API instance — so an
    # app mounting N APIs held N copies of tables it only ever reads. Keying
    # the cache on the registry itself collapses them: Hash keys compare by
    # value, so every API that registers the same content types shares one
    # table.
    #
    # Both the key and the table are frozen: the caller's registry stays
    # reachable (through +middleware.options[:content_types]+, among others)
    # and mutating a live key would corrupt a cache that is now shared
    # process-wide.

    class MimeTypesCache < Grape::Util::Cache
      def initialize
        super
        @cache = Hash.new do |h, from_settings|
          h[from_settings.dup.freeze] = from_settings.invert.transform_keys! { |mime_type| Grape::ContentTypes.media_type(mime_type) }.freeze
        end
      end
    end

    class LookupCache < Grape::Util::Cache
      def initialize
        super
        @cache = Hash.new do |h, from_settings|
          h[from_settings.dup.freeze] = from_settings.each_with_object({}) do |(format, media_type), lookup|
            lookup[format] = media_type
            lookup[format.is_a?(String) ? format.to_sym : format.to_s] = media_type
          end.freeze
        end
      end
    end
  end
end
