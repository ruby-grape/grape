# frozen_string_literal: true

module Grape
  module Util
    module Accept
      class MediaType < Rack::Accept::MediaType
        def parse_media_type(media_type)
          Grape::Util::Accept::Header.parse_media_type(media_type)
        end
      end
    end
  end
end
