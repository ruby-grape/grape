# frozen_string_literal: true

module Grape
  class Router
    class BaseRoute
      extend Forwardable

      delegate_missing_to :@options

      attr_reader :options, :pattern

      def_delegators :@pattern, :path, :origin
      def_delegators :@options, :description, :version, :requirements, :prefix, :anchor, :settings, :forward_match, *Grape::Util::ApiDescription::DSL_METHODS

      def initialize(pattern, options = {})
        @pattern = pattern
        @options = options.is_a?(ActiveSupport::OrderedOptions) ? options : ActiveSupport::OrderedOptions.new.update(options)
      end

      # see https://github.com/ruby-grape/grape/issues/1348
      def namespace
        @namespace ||= @options[:namespace]
      end

      def regexp_capture_index
        @regexp_capture_index ||= CaptureIndexCache[@index]
      end

      def pattern_regexp
        @pattern.to_regexp
      end

      def to_regexp(index)
        @index = index
        Regexp.new("(?<#{regexp_capture_index}>#{pattern_regexp})")
      end

      class CaptureIndexCache < Grape::Util::Cache
        def initialize
          super
          @cache = Hash.new do |h, index|
            h[index] = "_#{index}"
          end
        end
      end
    end
  end
end
