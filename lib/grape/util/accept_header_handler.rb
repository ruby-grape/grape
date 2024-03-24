# frozen_string_literal: true

module Grape
  module Util
    class AcceptHeaderHandler
      attr_reader :accept_header, :versions, :vendor, :strict, :cascade

      def initialize(accept_header:, versions:, **options)
        @accept_header = accept_header
        @versions = versions
        @vendor = options.fetch(:vendor, nil)
        @strict = options.fetch(:strict, false)
        @cascade = options.fetch(:cascade, true)
      end

      def match_best_quality_media_type!(content_types: Grape::ContentTypes::CONTENT_TYPES, allowed_methods: nil)
        return unless vendor

        strict_header_checks!
        media_type = Grape::Util::MediaType.best_quality(accept_header, available_media_types(content_types))
        if media_type
          yield media_type
        else
          fail!(allowed_methods)
        end
      end

      private

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

      def fail!(grape_allowed_methods)
        return grape_allowed_methods if grape_allowed_methods.present?

        media_types = q_values_mime_types.map { |mime_type| Grape::Util::MediaType.parse(mime_type) }
        vendor_not_found!(media_types) || version_not_found!(media_types)
      end

      def vendor_not_found!(media_types)
        return unless media_types.all? { |media_type| media_type&.vendor && media_type.vendor != vendor }

        invalid_accept_header!('API vendor not found.')
      end

      def version_not_found!(media_types)
        return unless media_types.all? { |media_type| media_type&.version && versions.exclude?(media_type.version) }

        invalid_version_header!('API version not found.')
      end

      def error_headers
        cascade ? { Grape::Http::Headers::X_CASCADE => 'pass' } : {}
      end

      def available_media_types(content_types)
        [].tap do |available_media_types|
          base_media_type = "application/vnd.#{vendor}"
          content_types.each_key do |extension|
            versions&.reverse_each do |version|
              available_media_types << "#{base_media_type}-#{version}+#{extension}"
              available_media_types << "#{base_media_type}-#{version}"
            end
            available_media_types << "#{base_media_type}+#{extension}"
          end

          available_media_types << base_media_type
          available_media_types.concat(content_types.values.flatten)
        end
      end
    end
  end
end
