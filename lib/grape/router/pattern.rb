# frozen_string_literal: true

module Grape
  class Router
    class Pattern
      extend Forwardable

      DEFAULT_CAPTURES = %w[format version].freeze

      attr_reader :origin, :path, :pattern, :to_regexp, :anchor, :version, :requirements

      def_delegators :pattern, :params
      def_delegators :to_regexp, :===
      alias match? ===

      # Build a Pattern from a raw path, namespace and the API's inheritable
      # settings. {Path} owns the settings-aware assembly of +origin+/+suffix+;
      # the Pattern itself stays value-based (see {#initialize}).
      def self.build(path:, namespace:, settings:, anchor:, params:, version:, requirements:)
        built_path = Path.new(path, namespace, settings)
        new(origin: built_path.origin, suffix: built_path.suffix, anchor:, params:, version:, requirements:)
      end

      def initialize(origin:, suffix:, anchor:, params:, version:, requirements:)
        @origin = origin
        @anchor = anchor
        @version = version
        @requirements = requirements
        @path = PatternCache[[build_path_from_pattern(@origin, anchor), suffix]]
        @pattern = MustermannPattern.new(@path, uri_decode: true, params:, capture: extract_capture(version, requirements))
        @to_regexp = @pattern.to_regexp
      end

      def captures_default
        to_regexp.names
                 .delete_if { |n| DEFAULT_CAPTURES.include?(n) }
                 .to_h { |k| [k, ''] }
      end

      private

      def extract_capture(version, requirements)
        return requirements if version.blank?

        requirements.merge(version: map_str(version))
      end

      def build_path_from_pattern(pattern, anchor)
        return pattern.dup.insert(pattern.rindex('/') + 1, '?') if pattern.end_with?('*path')
        return pattern if anchor
        return "#{pattern}?*path" if pattern.end_with?('/')

        "#{pattern}/?*path"
      end

      def map_str(value)
        Array.wrap(value).map(&:to_s)
      end

      class PatternCache < Grape::Util::Cache
        def initialize
          super
          @cache = Hash.new do |h, (pattern, suffix)|
            h[[pattern, suffix]] = -"#{pattern}#{suffix}"
          end
        end
      end
    end
  end
end
