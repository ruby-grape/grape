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

      def initialize(origin:, suffix:, anchor:, params:, format:, version:, requirements:)
        @origin = origin
        @path = PatternCache[[build_path_from_pattern(@origin, anchor), suffix]]
        @pattern = Mustermann::Grape.new(@path, uri_decode: true, params: params, capture: extract_capture(format, version, requirements))
        @to_regexp = @pattern.to_regexp
      end

      def captures_default
        to_regexp.names
                 .delete_if { |n| DEFAULT_CAPTURES.include?(n) }
                 .to_h { |k| [k, ''] }
      end

      private

      def extract_capture(format, version, requirements)
        capture = {}
        capture[:format] = map_str(format) if format.present?
        capture[:version] = map_str(version) if version.present?

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
