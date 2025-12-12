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

      from_settings.invert.transform_keys! { |k| k.include?(';') ? k.split(';', 2).first : k }
    end
  end
end
