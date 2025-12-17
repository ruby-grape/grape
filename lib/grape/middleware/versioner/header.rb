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
          match_best_quality_media_type! do |media_type|
            env.update(
              Grape::Env::API_TYPE => media_type.type,
              Grape::Env::API_SUBTYPE => media_type.subtype,
              Grape::Env::API_VENDOR => media_type.vendor,
              Grape::Env::API_VERSION => media_type.version,
              Grape::Env::API_FORMAT => media_type.format
            )
          end
        end

        private

        def match_best_quality_media_type!
          return unless vendor

          strict_header_checks!
          media_type = Grape::Util::MediaType.best_quality(accept_header, available_media_types)
          if media_type
            yield media_type
          else
            fail!
          end
        end

        def accept_header
          env['HTTP_ACCEPT']
        end

        def strict_header_checks!
          return unless strict

          accept_header_check!
          version_and_vendor_check!
        end

        def accept_header_check!
          return if accept_header.present?

          invalid_accept_header!('Accept header must be set.')
        end

        def version_and_vendor_check!
          return if versions.blank? || version_and_vendor?

          invalid_accept_header!('API vendor or version not found.')
        end

        def q_values_mime_types
          @q_values_mime_types ||= Rack::Utils.q_values(accept_header).map(&:first)
        end

        def version_and_vendor?
          q_values_mime_types.any? { |mime_type| Grape::Util::MediaType.match?(mime_type) }
        end

        def invalid_accept_header!(message)
          raise Grape::Exceptions::InvalidAcceptHeader.new(message, error_headers)
        end

        def invalid_version_header!(message)
          raise Grape::Exceptions::InvalidVersionHeader.new(message, error_headers)
        end

        def fail!
          return if env[Grape::Env::GRAPE_ALLOWED_METHODS].present?

          media_types = q_values_mime_types.map { |mime_type| Grape::Util::MediaType.parse(mime_type) }
          vendor_not_found!(media_types) || version_not_found!(media_types)
        end

        def vendor_not_found!(media_types)
          return unless media_types.all? { |media_type| media_type&.vendor && media_type.vendor != vendor }

          invalid_accept_header!('API vendor not found.')
        end

        def version_not_found!(media_types)
          return unless media_types.all? { |media_type| media_type&.version && versions && !versions.include?(media_type.version) }

          invalid_version_header!('API version not found.')
        end
      end
    end
  end
end
