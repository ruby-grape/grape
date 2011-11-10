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
        if options[:vendors] && env['HTTP_ACCEPT'] =~ /application\/vnd\.(.+)-(.+)\+(.+)/
          potential_vendor       = $1
          potential_version      = $2
          potential_content_type = $3

          if options[:vendors] && options[:vendors].include?(potential_vendor)
            if options[:versions] && options[:versions].include?(potential_version)
              env['api.version'] = potential_version
            end
          end
          throw :error, :status => 404, :message => "404 API Version Not Found" unless env['api.version']
        else
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
end
