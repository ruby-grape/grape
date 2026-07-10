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

      from_settings.invert.transform_keys! { |k| media_type(k) }
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
  end
end
