require 'grape/middleware/base'

module Grape
  module Middleware
    module Versioner
      # This middleware sets various version related rack environment variables
      # based on the uri path and removes the version substring from the uri
      # path. If the version substring does not match any potential initialized
      # versions, a 404 error is thrown.
      # 
      # Example: For a uri path
      #   /v1/resource
      # 
      # The following rack env variables are set and path is rewritten to
      # '/resource':
      # 
      #   env['api.version'] => 'v1'
      # 
      class Path < Base
        def default_options
          {
            :pattern => /.*/i
          }
        end

        def before
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
