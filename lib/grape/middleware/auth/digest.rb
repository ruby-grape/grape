require 'rack/auth/digest/md5'

module Grape
  module Middleware
    module Auth
      class Digest < Grape::Middleware::Auth::Base
        def base_request
          Rack::Auth::Digest::Request.new(env)
        end
      end
    end
  end
end
