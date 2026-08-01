# frozen_string_literal: true

module Grape
  module Util
    class MediaType
      attr_reader :type, :subtype, :vendor, :version, :format

      # based on the HTTP Accept header with the pattern:
      # application/vnd.:vendor-:version+:format
      #
      # Matched against a down-cased media type: they are case-insensitive
      # (RFC 9110 §8.3.1), while a vendor and version are declared in the DSL
      # in the case they will be compared in.
      VENDOR_VERSION_HEADER_REGEX = /\Avnd\.(?<vendor>[a-z0-9.\-_!^]+?)(?:-(?<version>[a-z0-9*.]+))?(?:\+(?<format>[a-z0-9*\-.]+))?\z/

      def initialize(type:, subtype:)
        @type = type
        @subtype = subtype
        VENDOR_VERSION_HEADER_REGEX.match(subtype) do |m|
          @vendor = m[:vendor]
          @version = m[:version]
          @format = m[:format]
        end
      end

      def ==(other)
        self.class == other.class &&
          other.type == type &&
          other.subtype == subtype &&
          other.vendor == vendor &&
          other.version == version &&
          other.format == format
      end
      alias eql? ==

      def hash
        [self.class, type, subtype, vendor, version, format].hash
      end

      class << self
        def best_quality(header, available_media_types)
          parse(best_quality_media_type(header, available_media_types))
        end

        def parse(media_type)
          return if media_type.blank?

          type, subtype = media_type.downcase.split('/', 2)
          return if type.blank? || subtype.blank?

          new(type:, subtype:)
        end

        def match?(media_type)
          return false if media_type.blank?

          subtype = media_type.downcase.split('/', 2).last
          return false if subtype.blank?

          VENDOR_VERSION_HEADER_REGEX.match?(subtype)
        end

        # The available types are registered in lower case and Rack matches them
        # literally, so the header has to be down-cased to be compared against
        # them at all.
        def best_quality_media_type(header, available_media_types)
          header.blank? ? available_media_types.first : Rack::Utils.best_q_match(header.downcase, available_media_types)
        end
      end

      private_class_method :best_quality_media_type
    end
  end
end
