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
        def initialize(app, **options)
          super
          @prefixes = [mount_path, Grape::Util::PathNormalizer.call(prefix)].select { |p| p.present? && p != '/' }.freeze
        end

        def before
          path_info = Grape::Util::PathNormalizer.call(env[Rack::PATH_INFO])
          return if path_info == '/'

          path_info = @prefixes.reduce(path_info) do |pi, path|
            pi.start_with?(path) ? pi.delete_prefix(path) : pi
          end

          slash_position = path_info.index('/', 1) # omit the first one
          return version_from_first_segment(path_info, slash_position) if slash_position

          version_from_only_segment(path_info)
        end

        private

        def version_from_first_segment(path_info, slash_position)
          potential_version = path_info[1..(slash_position - 1)]
          version_not_found! unless potential_version_match?(potential_version)
          env[Grape::Env::API_VERSION] = potential_version
        end

        # The path is a single segment (e.g. `GET /v1` — the root route of a
        # path-versioned API). Nothing follows to disambiguate a version from a
        # plain path or from a `.format` suffix (`/v1.json`), so the version is
        # only recorded on an exact match against the declared versions, and an
        # unmatched segment is left for the router to resolve — never a 404.
        def version_from_only_segment(path_info)
          candidate = path_info[1..]
          candidate = candidate[0...candidate.rindex('.')] while candidate.include?('.') && !declared_version?(candidate)
          env[Grape::Env::API_VERSION] = candidate if declared_version?(candidate)
        end

        def declared_version?(candidate)
          versions.present? && versions.include?(candidate)
        end
      end
    end
  end
end
