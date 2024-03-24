# frozen_string_literal: true

module Grape
  module Middleware
    module Versioner
      # This middleware sets various version related rack environment variables
      # based on the HTTP Accept header with the pattern:
      # application/vnd.:vendor-:version+:format
      #
      # Example: For request header
      #    Accept: application/vnd.mycompany.a-cool-resource-v1+json
      #
      # The following rack env variables are set:
      #
      #    env['api.type']    => 'application'
      #    env['api.subtype'] => 'vnd.mycompany.a-cool-resource-v1+json'
      #    env['api.vendor]   => 'mycompany.a-cool-resource'
      #    env['api.version]  => 'v1'
      #    env['api.format]   => 'json'
      #
      # If version does not match this route, then a 406 is raised with
      # X-Cascade header to alert Grape::Router to attempt the next matched
      # route.
      class Header < Base
        def before
          handler = Grape::Util::AcceptHeaderHandler.new(
            accept_header: env[Grape::Http::Headers::HTTP_ACCEPT],
            versions: options[:versions],
            **options.fetch(:version_options) { {} }
          )

          handler.match_best_quality_media_type!(
            content_types: content_types,
            allowed_methods: env[Grape::Env::GRAPE_ALLOWED_METHODS]
          ) do |media_type|
            env.update(
              Grape::Env::API_TYPE => media_type.type,
              Grape::Env::API_SUBTYPE => media_type.subtype,
              Grape::Env::API_VENDOR => media_type.vendor,
              Grape::Env::API_VERSION => media_type.version,
              Grape::Env::API_FORMAT => media_type.format
            )
          end
        end
      end
    end
  end
end
