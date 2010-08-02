require 'grape/middleware/base'

module Grape
  module Middleware
    class Prefixer < Base
      def prefix
        prefix = options[:prefix] || ""
        prefix.insert(0, '/') unless prefix.index('/') == 0
        prefix
      end
      
      def before
        if env['PATH_INFO'].index(prefix) == 0
          env['PATH_INFO'].gsub!(prefix, '')
          env['PATH_INFO'].insert(0, '/') unless env['PATH_INFO'].index('/') == 0
        end
      end
    end
  end
end