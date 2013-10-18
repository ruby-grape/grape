require 'grape/middleware/base'

module Grape
  module Middleware
    module Versioner
      # This middleware sets various version related rack environment variables
      # based on the request parameters and removes that parameter from the
      # request parameters for subsequent middleware and API.
      # If the version substring does not match any potential initialized
      # versions, a 404 error is thrown.
      # If the version substring is not passed the version (highest mounted)
      # version will be used.
      #
      # Example: For a uri path
      #   /resource?apiver=v1
      #
      # The following rack env variables are set and path is rewritten to
      # '/resource':
      #
      #   env['api.version'] => 'v1'
      class Param < Base
        def default_options
          {
            parameter: "apiver"
          }
        end

        def before
          paramkey = options[:parameter]
          potential_version = request.params[paramkey]

          unless potential_version.nil?
            if options[:versions] && !options[:versions].find { |v| v.to_s == potential_version }
              throw :error, status: 404, message: "404 API Version Not Found", headers: { 'X-Cascade' => 'pass' }
            end
            env['api.version'] = potential_version
            env['rack.request.query_hash'].delete(paramkey)
          end
        end

      end
    end
  end
end
