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
      def_delegators :@options, :description, *Grape::Util::ApiDescription::DSL_METHODS

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

      # @deprecated Use {#default_response}, the name grape-swagger asks for.
      #   This one has to be written out rather than delegated like the rest:
      #   an ActiveSupport::OrderedOptions answers an unknown name with that
      #   key's value, but +default+ is not unknown to it — it is +Hash#default+,
      #   the Hash's own default value — so a delegator would report nil for
      #   every route.
      def default
        Grape.deprecator.warn('`Grape::Router::Route#default` is deprecated. Use `#default_response` instead.')
        default_response
      end

      # Assigned eagerly in {#to_regexp} (router compilation) rather than
      # memoized here: this reader is called from request-time route matching
      # on instances shared across threads, so it must not write state.
      attr_reader :regexp_capture_index

      # The number of the group this route occupies in the union the router
      # compiled it into. Only the union can say what it is, so it is written
      # back by {Router#compile!} right after building one, and like
      # +regexp_capture_index+ it is never assigned at request time.
      attr_reader :regexp_capture_group

      def pattern_regexp
        @pattern.to_regexp
      end

      def to_regexp(index)
        @regexp_capture_index = CaptureIndexCache[index]
        Regexp.new("(?<#{regexp_capture_index}>#{pattern_regexp})")
      end

      # This route's named captures mapped to their group numbers in the router's
      # union, or nil when a union match would not reproduce what Mustermann
      # returns (see Route#params_for). Assigned in {#resolve_capture_group!},
      # never at request time -- instances are shared across threads.
      attr_reader :union_captures

      # @api private
      # @see #regexp_capture_group
      def resolve_capture_group!(union_named_captures)
        @regexp_capture_group = union_named_captures.fetch(regexp_capture_index).first
        @union_captures = resolve_union_captures
      end

      class CaptureIndexCache < Grape::Util::Cache
        def initialize
          super
          @cache = Hash.new do |h, index|
            h[index] = "_#{index}"
          end
        end
      end

      private

      # +to_regexp+'s wrapper is the group just before the pattern's own, and
      # +Regexp.union+ shifts numbering only by the groups preceding a branch --
      # what +regexp_capture_group+ counts. So the capture at position +n+ of the
      # route's regexp is group +regexp_capture_group + n+ of the union.
      def resolve_union_captures
        own = @pattern.to_regexp.named_captures
        return if own.empty?

        # Mustermann returns an Array for a name matched at several positions.
        return unless own.each_value.all? { |positions| positions.size == 1 }

        # Rejects param converters and the always-Array +splat+/+captures+ names.
        # Empty strings probe only what holds for every request; unescaping, the
        # one thing that does not, is gated on the path in Route#params_for.
        return unless @pattern.pattern.identity_params?(own.transform_values { '' })

        own.to_h { |name, positions| [name.to_sym, @regexp_capture_group + positions.first] }
      end
    end
  end
end
