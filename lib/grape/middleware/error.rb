require 'grape/middleware/base'

module Grape
  module Middleware
    class Error < Base
      def call!(env)
        @env = env
        result = catch :error do
          @app.call(@env)
        end
        
        result ||= {}
        result.is_a?(Hash) ? error_response(result) : result
      end
      
      def error_response(error = {})
        Rack::Response.new([(error[:message] || options[:default_message])], error[:status] || 403, error[:headers] || {}).finish
      end
    end
  end
end
