# frozen_string_literal: true

module Grape
  class Router
    class BaseRoute
      delegate_missing_to :@options

      attr_reader :index, :pattern, :options

      def initialize(**options)
        @options = ActiveSupport::OrderedOptions.new.update(options)
      end

      alias attributes options

      def regexp_capture_index
        CaptureIndexCache[index]
      end

      def pattern_regexp
        pattern.to_regexp
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
