# frozen_string_literal: true

module Grape
  # Represents a path to an endpoint.
  class Path
    DEFAULT_FORMAT_SEGMENT = '(/.:format)'
    NO_VERSIONING_WITH_VALID_PATH_FORMAT_SEGMENT = '(.:format)'
    VERSION_SEGMENT = ':version'

    attr_reader :origin, :suffix

    def initialize(raw_path, raw_namespace, settings)
      @origin = PartsCache[build_parts(raw_path, raw_namespace, settings)]
      @suffix = build_suffix(raw_path, raw_namespace, settings)
    end

    def to_s
      "#{origin}#{suffix}"
    end

    private

    def build_suffix(raw_path, raw_namespace, settings)
      if uses_specific_format?(settings)
        "(.#{settings[:format]})"
      elsif !uses_path_versioning?(settings) || (valid_part?(raw_namespace) || valid_part?(raw_path))
        NO_VERSIONING_WITH_VALID_PATH_FORMAT_SEGMENT
      else
        DEFAULT_FORMAT_SEGMENT
      end
    end

    def build_parts(raw_path, raw_namespace, settings)
      [].tap do |parts|
        add_part(parts, settings[:mount_path])
        add_part(parts, settings[:root_prefix])
        parts << VERSION_SEGMENT if uses_path_versioning?(settings)
        add_part(parts, raw_namespace)
        add_part(parts, raw_path)
      end
    end

    def add_part(parts, value)
      parts << value if value && not_slash?(value)
    end

    def not_slash?(value)
      value != '/'
    end

    def uses_specific_format?(settings)
      return false unless settings.key?(:format) && settings.key?(:content_types)

      settings[:format] && Array(settings[:content_types]).size == 1
    end

    def uses_path_versioning?(settings)
      return false unless settings.key?(:version) && settings[:version_options]&.key?(:using)

      settings[:version] && settings[:version_options][:using] == :path
    end

    def valid_part?(part)
      part&.match?(/^\S/) && not_slash?(part)
    end

    class PartsCache < Grape::Util::Cache
      def initialize
        super
        @cache = Hash.new do |h, parts|
          h[parts] = Grape::Router.normalize_path(parts.join('/'))
        end
      end
    end
  end
end
