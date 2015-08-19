module Grape
  # Represents a path to an endpoint.
  class Path
    def self.prepare(raw_path, namespace, settings)
      Path.new(raw_path, namespace, settings).path_with_suffix
    end

    attr_reader :raw_path, :namespace, :settings

    def initialize(raw_path, namespace, settings)
      @raw_path = raw_path
      @namespace = namespace
      @settings = settings
    end

    def mount_path
      settings[:mount_path]
    end

    def root_prefix
      split_setting(:root_prefix)
    end

    def uses_specific_format?
      !!(settings[:format] && settings[:content_types].size == 1)
    end

    def uses_path_versioning?
      !!(settings[:version] && settings[:version_options][:using] == :path)
    end

    def namespace?
      namespace && namespace.to_s =~ /^\S/ && namespace != '/'
    end

    def path?
      raw_path && raw_path.to_s =~ /^\S/ && raw_path != '/'
    end

    def suffix
      if uses_specific_format?
        "(.#{settings[:format]})"
      elsif !uses_path_versioning? || (namespace? || path?)
        '(.:format)'
      else
        '(/.:format)'
      end
    end

    def path
      Rack::Mount::Utils.normalize_path(parts.join('/'))
    end

    def path_with_suffix
      "#{path}#{suffix}"
    end

    def to_s
      path_with_suffix
    end

    private

    def parts
      parts = [mount_path, root_prefix].compact
      parts << ':version' if uses_path_versioning?
      parts << namespace.to_s
      parts << raw_path.to_s
      parts.flatten.reject { |part| part == '/' }
    end

    def split_setting(key)
      return if settings[key].nil?
      settings[key].to_s.split('/')
    end
  end
end
