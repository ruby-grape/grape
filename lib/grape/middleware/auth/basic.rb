require 'rack/auth/basic'

module Grape
  module Middleware
    module Auth
      class Basic < Grape::Middleware::Base
        attr_reader :authenticator
        
        def initialize(app, options = {}, &authenticator)
          super(app, options)
          @authenticator = authenticator
        end
        
        def basic_request
          Rack::Auth::Basic::Request.new(env)
        end
        
        def credentials
          basic_request.provided?? basic_request.credentials : [nil, nil]
        end
        
        def before
          unless authenticator.call(*credentials)
            throw :error, :status => 401, :message => "API Authorization Failed."
          end
        end
      end
    end
  end
end