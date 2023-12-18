# frozen_string_literal: true

require 'grape/middleware/base'
require 'grape/util/media_type'

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
          header = env[Grape::Http::Headers::HTTP_ACCEPT]
          qvalues = Grape::Util::MediaType.q_values(header)
          strict_header_checks(qvalues) if strict?

          media_type = Grape::Util::MediaType.from_best_quality_media_type(header, available_media_types)

          if media_type
            env[Grape::Env::API_TYPE] = media_type.type
            env[Grape::Env::API_SUBTYPE] = media_type.subtype
            env[Grape::Env::API_VENDOR] = media_type.vendor
            env[Grape::Env::API_VERSION] = media_type.version
            env[Grape::Env::API_FORMAT] = media_type.format
          elsif !env[Grape::Env::GRAPE_ALLOWED_METHODS]
            media_types = qvalues.map { |mime_type, _quality| Grape::Util::MediaType.parse(mime_type) }
            if headers_contain_wrong_vendor?(media_types)
              fail_with_invalid_accept_header!('API vendor not found.')
            elsif headers_contain_wrong_version?(media_types)
              fail_with_invalid_version_header!('API version not found.')
            end
          end
        end

        private

        def strict_header_checks(qvalues)
          strict_accept_header_presence_check(qvalues)
          strict_version_vendor_accept_header_presence_check(qvalues)
        end

        def strict_accept_header_presence_check(qvalues)
          return if qvalues.any?

          fail_with_invalid_accept_header!('Accept header must be set.')
        end

        def strict_version_vendor_accept_header_presence_check(qvalues)
          return if versions.blank? || an_accept_header_with_version_and_vendor_is_present?(qvalues)

          fail_with_invalid_accept_header!('API vendor or version not found.')
        end

        def an_accept_header_with_version_and_vendor_is_present?(qvalues)
          qvalues.any? { |mime_type, _quality| Grape::Util::MediaType.match?(mime_type) }
        end

        def fail_with_invalid_accept_header!(message)
          raise Grape::Exceptions::InvalidAcceptHeader.new(message, error_headers)
        end

        def fail_with_invalid_version_header!(message)
          raise Grape::Exceptions::InvalidVersionHeader.new(message, error_headers)
        end

        def available_media_types
          [].tap do |available_media_types|
            base_media_type = "application/vnd.#{vendor}"
            content_types.each_key do |extension|
              versions.reverse_each do |version|
                available_media_types << "#{base_media_type}-#{version}+#{extension}"
                available_media_types << "#{base_media_type}-#{version}"
              end
              available_media_types << "#{base_media_type}+#{extension}"
            end

            available_media_types << base_media_type
            available_media_types.concat(content_types.values.flatten)
          end
        end

        def headers_contain_wrong_vendor?(media_types)
          media_types.all? { |media_type| media_type&.vendor && media_type.vendor != vendor }
        end

        def headers_contain_wrong_version?(media_types)
          media_types.all? { |media_type| media_type&.version && versions.exclude?(media_type.version) }
        end

        def versions
          @versions ||= options[:versions] || []
        end

        def vendor
          version_options && version_options[:vendor]
        end

        def strict?
          version_options && version_options[:strict]
        end

        def version_options
          options[:version_options]
        end

        # By default those errors contain an `X-Cascade` header set to `pass`,
        # which allows nesting and stacking of routes
        # (see Grape::Router for more
        # information). To prevent # this behavior, and not add the `X-Cascade`
        # header, one can set the `:cascade` option to `false`.
        def cascade?
          if version_options&.key?(:cascade)
            version_options[:cascade]
          else
            true
          end
        end

        def error_headers
          cascade? ? { Grape::Http::Headers::X_CASCADE => 'pass' } : {}
        end
      end
    end
  end
end
