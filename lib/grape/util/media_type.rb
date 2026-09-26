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

      # The pattern above cannot tell where a vendor ends and a version begins
      # when either holds a hyphen, so it keeps hyphens out of the version: a
      # dated version such as +2024-06-20+ read as vendor +acme-2024-06+ and
      # version +20+. Given the vendor it is parsed for, the vendor is spelled
      # out and everything after it up to the format is the version.
      #
      # Keyed by the vendors APIs declare, never by what a client sends.
      class VendorVersionHeaderRegexCache < Grape::Util::Cache
        def initialize
          super
          @cache = Hash.new do |h, vendor|
            h[vendor] = /\Avnd\.(?<vendor>#{Regexp.escape(vendor)})(?:-(?<version>[a-z0-9*.-]+))?(?:\+(?<format>[a-z0-9*\-.]+))?\z/
          end
        end
      end

      # Immutable, strings included: the header versioner shares one instance
      # per declared media type across every request that sends it, and these
      # strings are what it writes into the env. The arguments are copied
      # rather than frozen, as they are the caller's.
      #
      # A +subtype+ naming a vendor other than +vendor+ is parsed as it would
      # be without one.
      def initialize(type:, subtype:, vendor: nil)
        @type = -type
        @subtype = -subtype
        match = VendorVersionHeaderRegexCache[vendor].match(@subtype) if vendor
        match ||= VENDOR_VERSION_HEADER_REGEX.match(@subtype)
        if match
          @vendor = match[:vendor].freeze
          @version = match[:version].freeze
          @format = match[:format].freeze
        end
        freeze
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
        def best_quality(header, available_media_types, vendor: nil)
          parse(best_quality_media_type(header, available_media_types), vendor:)
        end

        def parse(media_type, vendor: nil)
          return if media_type.blank?

          type, subtype = media_type.downcase.split('/', 2)
          return if type.blank? || subtype.blank?

          new(type:, subtype:, vendor:)
        end

        def match?(media_type)
          return false if media_type.blank?

          VENDOR_VERSION_HEADER_REGEX.match?(media_type.downcase.split('/', 2).last)
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
