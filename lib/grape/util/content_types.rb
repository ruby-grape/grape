module Grape
  module ContentTypes
    # Content types are listed in order of preference.
    CONTENT_TYPES = ActiveSupport::OrderedHash[
      :xml,  'application/xml',
      :serializable_hash, 'application/json',
      :json, 'application/json',
      :jsonapi, 'application/vnd.api+json',
      :atom, 'application/atom+xml',
      :rss,  'application/rss+xml',
      :txt,  'text/plain',
   ]

    def self.content_types_for(from_settings)
      from_settings || Grape::ContentTypes::CONTENT_TYPES
    end
  end
end
