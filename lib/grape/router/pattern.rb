# frozen_string_literal: true

module Grape
  class Router
    class Pattern
      extend Forwardable

      DEFAULT_CAPTURES = %w[format version].freeze

      attr_reader :origin, :path, :pattern, :to_regexp

      def_delegators :pattern, :params
      def_delegators :to_regexp, :===
      alias match? ===

      def initialize(origin, suffix, options)
        @origin = origin
        @path = build_path(origin, options[:anchor], suffix)
        @pattern = build_pattern(@path, options[:params], options[:format], options[:version], options[:requirements])
        @to_regexp = @pattern.to_regexp
      end

      def captures_default
        to_regexp.names
                 .delete_if { |n| DEFAULT_CAPTURES.include?(n) }
                 .to_h { |k| [k, ''] }
      end

      private

      def build_pattern(path, params, format, version, requirements)
        Mustermann::Grape.new(
          path,
          uri_decode: true,
          params: params,
          capture: extract_capture(format, version, requirements)
        )
      end

      def build_path(pattern, anchor, suffix)
        PatternCache[[build_path_from_pattern(pattern, anchor), suffix]]
      end

      def extract_capture(format, version, requirements)
        capture = {}.tap do |h|
          h[:format] = map_str(format) if format.present?
          h[:version] = map_str(version) if version.present?
        end

        return capture if requirements.blank?

        requirements.merge(capture)
      end

      def build_path_from_pattern(pattern, anchor)
        if pattern.end_with?('*path')
          pattern.dup.insert(pattern.rindex('/') + 1, '?')
        elsif anchor
          pattern
        elsif pattern.end_with?('/')
          "#{pattern}?*path"
        else
          "#{pattern}/?*path"
        end
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
