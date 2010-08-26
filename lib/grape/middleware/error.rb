require 'grape/middleware/base'

module Grape
  module Middleware
    class Error < Base
      def call!(env)
        @env = env
        err = catch :error do
          @app.call(@env)
        end
        
        error_response(err)
      end
      
      def error_response(error = {})
        Rack::Response.new([(error[:message] || options[:default_message])], error[:status] || 403, error[:headers] || {}).finish
      end
    end
  end
end