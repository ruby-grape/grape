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
          routed = routed_version
          return env[Grape::Env::API_VERSION] = routed if routed

          path_info = env[Grape::Env::GRAPE_NORMALIZED_PATH] || Grape::Util::PathNormalizer.call(env[Rack::PATH_INFO])
          return if path_info == '/'

          # `each` rather than `reduce`: Array does not override Enumerable's,
          # so the generic accumulator path costs more than the work it drives
          # on a list that holds at most a mount path and a prefix — and most
          # often nothing at all.
          @prefixes.each { |prefix| path_info = path_info.delete_prefix(prefix) if path_info.start_with?(prefix) }

          slash_position = path_info.index('/', 1) # omit the first one
          return version_from_first_segment(path_info, slash_position) if slash_position

          version_from_only_segment(path_info)
        end

        private

        # Under path versioning every route pattern carries the version as a
        # named capture (Pattern::Path#build_parts inserts it), constrained to
        # the declared versions -- so the router has already sliced the segment
        # out and validated it, and re-deriving it from PATH_INFO would repeat
        # the normalize, prefix-strip and slice below for the same answer.
        #
        # Nil, and the path parsed as before, when there are no routing args at
        # all (the middleware used outside a Grape router) and for the greedy
        # routes behind auto-OPTIONS and 405, which capture nothing. An Array
        # means the route declared a +:version+ segment of its own on top of the
        # versioning one: Mustermann then reports the capture as every position
        # it matched rather than the single segment recorded here, so that too
        # is left to the path parse.
        def routed_version
          version = env[Grape::Env::GRAPE_ROUTING_ARGS]&.[](:version)
          version if version.is_a?(String)
        end

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
