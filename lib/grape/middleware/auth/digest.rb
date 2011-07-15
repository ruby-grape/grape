require 'rack/auth/digest/md5'

module Grape
  module Middleware
    module Auth
      class Digest < Grape::Middleware::Base
        attr_reader :authenticator
        
        def initialize(app, options = {}, &authenticator)
          super(app, options)
          @authenticator = authenticator
        end
        
        def digest_request
          Rack::Auth::Digest::Request.new(env)
        end
        
        def credentials
          digest_request.provided?? digest_request.credentials : [nil, nil]
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
