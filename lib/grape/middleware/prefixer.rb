require 'rack/mount/utils'
require 'grape'

module Grape
  module Middleware
    class Prefixer < Base
      def prefix
        prefix = options[:prefix] || ""
        prefix = Rack::Mount::Utils.normalize_path(prefix)
        prefix
      end
      
      def before
        if env['PATH_INFO'].index(prefix) == 0
          env['PATH_INFO'].sub!(prefix, '')
          env['PATH_INFO'] = Rack::Mount::Utils.normalize_path(env['PATH_INFO'])
        end
      end
    end
  end
end