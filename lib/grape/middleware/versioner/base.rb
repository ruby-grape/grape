# frozen_string_literal: true

module Grape
  module Middleware
    module Versioner
      class Base < Grape::Middleware::Base
        include Grape::Middleware::PrecomputedContentTypes

        DEFAULT_OPTIONS = {
          mount_path: nil,
          pattern: /.*/i,
          prefix: nil,
          version_options: {
            cascade: true,
            parameter: 'apiver',
            strict: false,
            vendor: nil
          }.freeze
        }.freeze

        CASCADE_PASS_HEADER = { 'X-Cascade' => 'pass' }.freeze

        def self.inherited(klass)
          super
          Versioner.register(klass)
        end

        attr_reader :available_media_types, :cascade, :error_headers, :mount_path, :parameter,
                    :pattern, :prefix, :strict, :vendor, :versions

        def initialize(app, **options)
          super
          version_options = @options[:version_options]
          @cascade = version_options[:cascade]
          @mount_path = @options[:mount_path]
          @parameter = version_options[:parameter]
          @pattern = @options[:pattern]
          @prefix = @options[:prefix]
          @strict = version_options[:strict]
          @vendor = version_options[:vendor]
          @versions = @options[:versions]&.map(&:to_s) # making sure versions are strings to ease potential match
          @error_headers = @cascade ? CASCADE_PASS_HEADER : {}
          @available_media_types = build_available_media_types
        end

        def potential_version_match?(potential_version)
          versions.blank? || versions.include?(potential_version)
        end

        def version_not_found!
          throw :error, status: 404, message: '404 API Version Not Found', headers: CASCADE_PASS_HEADER
        end

        private

        def build_available_media_types
          media_types = []
          base_media_type = "application/vnd.#{vendor}"
          content_types.each_key do |extension|
            versions&.reverse_each do |version|
              media_types << "#{base_media_type}-#{version}+#{extension}"
              media_types << "#{base_media_type}-#{version}"
            end
            media_types << "#{base_media_type}+#{extension}"
          end

          media_types << base_media_type
          media_types.concat(content_types.values.flatten)
          media_types
        end
      end
    end
  end
end
