require 'forwardable'
require 'mustermann/grape'

module Grape
  class Router
    class Pattern
      DEFAULT_PATTERN_OPTIONS   = { uri_decode: true, type: :grape }.freeze
      DEFAULT_SUPPORTED_CAPTURE = [:format, :version].freeze

      attr_reader :origin, :path, :capture, :pattern

      extend Forwardable
      def_delegators :pattern, :named_captures, :params
      def_delegators :@regexp, :===
      alias_method :match?, :===

      def initialize(pattern, options = {})
        @origin  = pattern
        @path    = build_path(pattern, options)
        @capture = extract_capture(options)
        @pattern = Mustermann.new(@path, pattern_options)
        @regexp  = to_regexp
      end

      def to_regexp
        @to_regexp ||= @pattern.to_regexp
      end

      private

      def pattern_options
        options = DEFAULT_PATTERN_OPTIONS.dup
        options.merge!(capture: capture) if capture.present?
        options
      end

      def build_path(pattern, options = {})
        pattern << '*path' unless options[:anchor] || pattern.end_with?('*path')
        pattern + options[:suffix].to_s
      end

      def extract_capture(options = {})
        requirements = {}.merge(options[:requirements])
        supported_capture.each_with_object(requirements) do |field, capture|
          option = Array(options[field])
          capture[field] = option.map(&:to_s) if option.present?
        end
      end

      def supported_capture
        DEFAULT_SUPPORTED_CAPTURE
      end
    end
  end
end
