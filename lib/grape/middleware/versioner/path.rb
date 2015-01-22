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
            pattern: /.*/i
          }
        end

        def before
          path = env['PATH_INFO'].dup

          if prefix && path.index(prefix) == 0
            path.sub!(prefix, '')
            path = Rack::Mount::Utils.normalize_path(path)
          end

          env['api.version'] = default_version if default_version

          pieces = path.split('/')
          potential_version = pieces[1]
          if potential_version =~ options[:pattern]
            if unrecognized_version?(potential_version)
              unless default_version
                throw :error, status: 404, message: '404 API Version Not Found'
              end
            else
              env['api.version'] = potential_version
            end
          end
        end

        private

        def prefix
          Rack::Mount::Utils.normalize_path(options[:prefix].to_s) if options[:prefix]
        end

        def default_version
          options[:version_options] && options[:version_options][:default]
        end

        def unrecognized_version?(potential_version)
          options[:versions] && !options[:versions].find do |v|
            v.to_s == potential_version
          end
        end
      end
    end
  end
end
