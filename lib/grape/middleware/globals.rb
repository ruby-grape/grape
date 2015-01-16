# This Middleware is not loaded by grape by default.
# If you intend to use it you must first:
#   require 'grape/middleware/globals'
# See the spec for examples.
#
require 'grape/middleware/base'

module Grape
  module Middleware
    class Globals < Base
      # NOTE: If you have Grape mounted as a Rack endpoint in a Rails stack action dispatch may have moved the params
      # If your params are not showing up,
      #   then you may need to override this method and
      #   have it load params from @env['action_dispatch.request.request_parameters'] instead of request.params
      def before
        request = Grape::Request.new(@env)
        @env['grape.request.headers'] = request.headers
        @env['grape.request.params'] = request.params
      end
    end
  end
end
