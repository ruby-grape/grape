# frozen_string_literal: true

module Spec
  module Support
    module Helpers
      def rack_versioned_headers
        if Gem::Version.new(Rack.release) < Gem::Version.new('3')
          {
            cache_control: 'Cache-Control',
            content_length: 'Content-Length',
            content_type: 'Content-Type',
            grape_likes_symbolic: 'Grape-Likes-Symbolic',
            location: 'Location',
            symbol_header: 'Symbol-Header',
            transfer_encoding: 'Transfer-Encoding',
            x_access_token: 'X-Access-Token',
            x_cascade: 'X-Cascade',
            x_grape_client: 'X-Grape-Client',
            x_grape_is_cool: 'X-Grape-Is-Cool'
          }
        else
          {
            cache_control: 'cache-control',
            content_length: 'content-length',
            content_type: 'content-type',
            grape_likes_symbolic: 'grape-likes-symbolic',
            location: 'location',
            symbol_header: 'symbol-header',
            transfer_encoding: 'transfer-encoding',
            x_access_token: 'x-access-token',
            x_cascade: 'x-cascade',
            x_grape_client: 'x-grape-client',
            x_grape_is_cool: 'x-grape-is-cool'
          }
        end
      end
    end
  end
end
