# frozen_string_literal: true

module Grape
  class Router
    class BaseRoute
      extend Forwardable

      delegate_missing_to :@options

      attr_reader :options, :pattern, :prefix, :settings, :namespace

      # +version+, +anchor+ and +requirements+ shape the matcher, so they are
      # read from the pattern rather than stored again on the route.
      def_delegators :@pattern, :path, :origin, :version, :anchor, :requirements
      def_delegators :@options, :description, *(Grape::Util::ApiDescription::DSL_METHODS - %i[default])

      def initialize(pattern, options = {}, namespace: nil, prefix: nil, settings: nil)
        @pattern = pattern
        @options = options.is_a?(ActiveSupport::OrderedOptions) ? options : ActiveSupport::OrderedOptions.new.update(options)
        @namespace = namespace
        @prefix = prefix
        @settings = settings
      end

      # +success+ and +failure+ are the +desc+ DSL's names for +entity+ and
      # +http_codes+: the block form writes the canonical key, a keyword option
      # keeps the name it was written with, so both spellings are read here.
      # Without this they resolve through +delegate_missing_to+, which answers
      # nil for whichever of the two keys the description did not use.
      def success
        @options[:entity] || @options[:success]
      end

      def failure
        @options[:http_codes] || @options[:failure]
      end

      # +default+ is the one +desc+ key that cannot be delegated to +@options+.
      # An ActiveSupport::OrderedOptions answers an unknown name with that key's
      # value, but +default+ is not unknown to it — it is +Hash#default+, the
      # Hash's own default value — so delegating it reported nil for every route.
      def default
        @options[:default]
      end

      # Assigned eagerly in {#to_regexp} (router compilation) rather than
      # memoized here: this reader is called from request-time route matching
      # on instances shared across threads, so it must not write state.
      attr_reader :regexp_capture_index

      def pattern_regexp
        @pattern.to_regexp
      end

      def to_regexp(index)
        @regexp_capture_index = CaptureIndexCache[index]
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
