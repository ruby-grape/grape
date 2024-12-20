# frozen_string_literal: true

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
        def before
          potential_version = Rack::Utils.parse_nested_query(env[Rack::QUERY_STRING])[parameter_key]
          return if potential_version.blank?

          version_not_found! unless potential_version_match?(potential_version)
          env[Grape::Env::API_VERSION] = potential_version
          env[Rack::RACK_REQUEST_QUERY_HASH].delete(parameter_key) if env.key? Rack::RACK_REQUEST_QUERY_HASH
        end
      end
    end
  end
end
