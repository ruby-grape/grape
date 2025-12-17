# frozen_string_literal: true

module Grape
  module Middleware
    module Versioner
      # This middleware sets various version related rack environment variables
      # based on the HTTP Accept-Version header
      #
      # Example: For request header
      #    Accept-Version: v1
      #
      # The following rack env variables are set:
      #
      #    env['api.version']  => 'v1'
      #
      # If version does not match this route, then a 406 is raised with
      # X-Cascade header to alert Grape::Router to attempt the next matched
      # route.
      class AcceptVersionHeader < Base
        def before
          potential_version = try_scrub(env['HTTP_ACCEPT_VERSION'])
          not_acceptable!('Accept-Version header must be set.') if strict && potential_version.blank?

          return if potential_version.blank?

          not_acceptable!('The requested version is not supported.') unless potential_version_match?(potential_version)
          env[Grape::Env::API_VERSION] = potential_version
        end

        private

        def not_acceptable!(message)
          throw :error, status: 406, headers: error_headers, message: message
        end
      end
    end
  end
end
