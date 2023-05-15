# frozen_string_literal: true

require 'grape/util/registrable'

module Grape
  module ContentTypes
    extend Util::Registrable

    # Content types are listed in order of preference.
    CONTENT_TYPES = {
      xml: 'application/xml',
      serializable_hash: 'application/json',
      json: 'application/json',
      binary: 'application/octet-stream',
      txt: 'text/plain'
    }.freeze

    class << self
      def content_types_for_settings(settings)
        settings&.inject(:merge!)
      end

      def content_types_for(from_settings)
        from_settings.presence || Grape::ContentTypes::CONTENT_TYPES.merge(default_elements)
      end
    end
  end
end
