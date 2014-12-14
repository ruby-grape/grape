module Grape
  module ContentTypes
    # Content types are listed in order of preference.
    CONTENT_TYPES = ActiveSupport::OrderedHash[
                    :xml,  'application/xml',
                    :serializable_hash, 'application/json',
                    :json, 'application/json',
                    :binary, 'application/octet-stream',
                    :txt,  'text/plain'
   ]

    def self.content_types_for_settings(settings)
      return nil if settings.nil? || settings.blank?

      settings.each_with_object(ActiveSupport::OrderedHash.new) { |value, result| result.merge!(value) }
    end

    def self.content_types_for(from_settings)
      if from_settings.present?
        from_settings
      else
        Grape::ContentTypes::CONTENT_TYPES
      end
    end
  end
end
