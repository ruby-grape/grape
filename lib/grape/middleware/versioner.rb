require 'grape/middleware/base'

module Grape
  module Middleware
    class Versioner < Base
      def default_options
        {
          :pattern => /.*/i
        }
      end
      
      def before
        pieces = env['PATH_INFO'].split('/')
        potential_version = pieces[1]
        if potential_version =~ options[:pattern]
          truncated_path = "/#{pieces[2..-1].join('/')}"
          env['api.version'] = potential_version
          env['PATH_INFO'] = truncated_path
        end
      end
    end
  end
end