# frozen_string_literal: true

module Grape
  class Router
    class BaseRoute
      extend Forwardable

      delegate_missing_to :@options

      attr_reader :options, :pattern, :version, :prefix, :requirements, :anchor, :settings, :namespace

      def_delegators :@pattern, :path, :origin
      def_delegators :@options, :description, *Grape::Util::ApiDescription::DSL_METHODS

      def initialize(pattern, options = {}, version: nil, namespace: nil, prefix: nil, requirements: nil, anchor: nil, settings: nil)
        @pattern = pattern
        @options = options.is_a?(ActiveSupport::OrderedOptions) ? options : ActiveSupport::OrderedOptions.new.update(options)
        @version = version
        @namespace = namespace
        @prefix = prefix
        @requirements = requirements
        @anchor = anchor
        @settings = settings
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
