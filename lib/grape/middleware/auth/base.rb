require 'rack/auth/basic'

module Grape
  module Middleware
    module Auth
      class Base < Grape::Middleware::Base
        attr_reader :authenticator

        def initialize(app, options = {}, &authenticator)
          super(app, options)
          @authenticator = authenticator
        end

        def base_request
          raise NotImplementedError, "You must implement base_request."
        end

        def credentials
          base_request.provided? ? base_request.credentials : [nil, nil]
        end

        def before
          unless authenticator.call(*credentials)
            throw :error, status: 401, message: "API Authorization Failed."
          end
        end
      end
    end
  end
end
