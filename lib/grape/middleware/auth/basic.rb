require 'rack/auth/basic'

module Grape
  module Middleware
    module Auth
      class Basic < Grape::Middleware::Auth::Base
        def base_request
          Rack::Auth::Basic::Request.new(env)
        end
      end
    end
  end
end
