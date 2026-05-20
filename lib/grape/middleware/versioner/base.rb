# frozen_string_literal: true

module Grape
  module Middleware
    module Versioner
      class Base < Grape::Middleware::Base
        extend Forwardable
        include Grape::Middleware::PrecomputedContentTypes

        Options = Data.define(
          :content_types, :format, :mount_path, :pattern, :prefix, :version_options, :versions
        ) do
          def initialize(
            content_types: nil, format: nil, mount_path: nil, pattern: /.*/i, prefix: nil,
            version_options: Grape::DSL::VersionOptions.new, versions: nil
          )
            super
          end
        end

        CASCADE_PASS_HEADER = { 'X-Cascade' => 'pass' }.freeze

        def self.inherited(klass)
          super
          Versioner.register(klass)
        end

        attr_reader :available_media_types, :error_headers, :versions

        def_delegators :options, :mount_path, :pattern, :prefix, :version_options
        def_delegators :version_options, :cascade, :parameter, :strict, :vendor

        def initialize(app, **options)
          super
          @versions = self.options.versions&.map(&:to_s) # making sure versions are strings to ease potential match
          @error_headers = cascade ? CASCADE_PASS_HEADER : {}
          @available_media_types = build_available_media_types
        end

        def potential_version_match?(potential_version)
          versions.blank? || versions.include?(potential_version)
        end

        def version_not_found!
          throw :error, Grape::Exceptions::ErrorResponse.new(status: 404, message: '404 API Version Not Found', headers: CASCADE_PASS_HEADER)
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
