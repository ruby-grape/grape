require 'grape/middleware/base'

module Grape
  module Middleware
    class Globals < Base
      def before
        request = Grape::Request.new(@env)
        @env['grape.request'] = request
        @env['grape.request.headers'] = request.headers
        @env['grape.request.params'] = request.params if @env['rack.input']
      end
    end
  end
end
