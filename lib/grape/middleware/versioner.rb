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
        env['api.original_path_info'] = env['PATH_INFO'].dup
        pieces = env['PATH_INFO'].split('/')
        potential_version = pieces[1]
        if potential_version =~ options[:pattern]
          if options[:versions] && !options[:versions].include?(potential_version)
            throw :error, :status => 404, :message => "404 API Version Not Found"
          end
          
          truncated_path = "/#{pieces[2..-1].join('/')}"
          env['api.version'] = potential_version
          env['PATH_INFO'] = truncated_path
        end
      end
    end
  end
end