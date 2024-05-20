# frozen_string_literal: true

module Grape
  class Router
    class Pattern
      extend Forwardable

      DEFAULT_CAPTURES = %w[format version].freeze

      attr_reader :origin, :path, :pattern, :to_regexp

      def_delegators :pattern, :named_captures, :params
      def_delegators :to_regexp, :===
      alias match? ===

      def initialize(pattern, **options)
        @origin = pattern
        @path = build_path(pattern, anchor: options[:anchor], suffix: options[:suffix])
        @pattern = build_pattern(@path, options)
        @to_regexp = @pattern.to_regexp
      end

      def captures_default
        to_regexp.names
                 .delete_if { |n| DEFAULT_CAPTURES.include?(n) }
                 .to_h { |k| [k, ''] }
      end

      private

      def build_pattern(path, options)
        Mustermann::Grape.new(
          path,
          uri_decode: true,
          params: options[:params],
          capture: extract_capture(**options)
        )
      end

      def build_path(pattern, anchor: false, suffix: nil)
        PatternCache[[build_path_from_pattern(pattern, anchor: anchor), suffix]]
      end

      def extract_capture(**options)
        sliced_options = options
                         .slice(:format, :version)
                         .delete_if { |_k, v| v.blank? }
                         .transform_values { |v| Array.wrap(v).map(&:to_s) }
        return sliced_options if options[:requirements].blank?

        options[:requirements].merge(sliced_options)
      end

      def build_path_from_pattern(pattern, anchor: false)
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
