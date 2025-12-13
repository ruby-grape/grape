# frozen_string_literal: true

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
        def before
          path_info = Grape::Router.normalize_path(env[Rack::PATH_INFO])
          return if path_info == '/'

          [mount_path, Grape::Router.normalize_path(prefix)].each do |path|
            path_info = path_info.delete_prefix(path) if path.present? && path != '/' && path_info.start_with?(path)
          end

          slash_position = path_info.index('/', 1) # omit the first one
          return unless slash_position

          potential_version = path_info[1..(slash_position - 1)]
          return unless potential_version.match?(pattern)

          version_not_found! unless potential_version_match?(potential_version)
          env[Grape::Env::API_VERSION] = potential_version
        end
      end
    end
  end
end
