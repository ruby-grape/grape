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
        @captures = @to_regexp.names.any?
      end

      # True when the compiled pattern has named captures to extract from a
      # matched path. A fully static path has none — not even +format+, which
      # the suffix spells as a literal — so asking Mustermann for its params
      # would run the regexp a second time (the router's union already matched
      # it) only to hand back an empty Hash.
      #
      # Resolved once here rather than per request: +Regexp#names+ builds an
      # Array and a String per capture, and Ruby offers no predicate that skips
      # that (+named_captures+ builds a Hash, and scanning the source for
      # <tt>(?<</tt> would count lookbehinds, which name nothing).
      def captures?
        @captures
      end

      def captures_default
        to_regexp.names
                 .delete_if { |n| DEFAULT_CAPTURES.include?(n) }
                 .to_h { |k| [k, ''] }
      end

      private

      # The declared versions constrain the +:version+ capture. They are handed
      # to Mustermann as one alternation Regexp rather than as the Array of
      # Strings they arrive in, because an Array capture makes Mustermann build
      # a *converter* for the capture -- and for an Array of plain Strings that
      # converter is the identity function (Mustermann only derives one from a
      # Class or a Symbol, so every entry contributes nothing and the lambda
      # falls through to `|| string`).
      #
      # A non-empty converter table costs every request on the route: it makes
      # Mustermann's +identity_params?+ fast path unreachable, so +params+
      # rebuilds the capture Hash through +map_param+ and calls the do-nothing
      # lambda on each value. Passing a Regexp registers no converter at all.
      #
      # The generated matcher differs in one respect: Mustermann expands an
      # Array entry the way it expands a path literal, so each character also
      # matches its own percent-encoding (+v1+ as <tt>(?:v|%76)(?:1|%31)</tt>).
      # A Regexp is inserted verbatim, so a percent-encoded version segment no
      # longer matches the route. It never reached the endpoint anyway --
      # {Versioner::Base#potential_version_match?} compares the raw segment
      # against the declared versions, so +/api/%76%31/x+ was matched here and
      # then rejected as an unknown version, ending in the same cascading 404
      # the router now returns directly.
      #
      # +Regexp.union+ takes Strings and Regexps only, and +version+ accepts
      # Symbols and Integers too, so the entries are coerced first. A lone one
      # would survive without it -- the single-argument path goes through
      # +Regexp.escape+, which does accept a Symbol -- but a second raises
      # TypeError.
      def extract_capture(version, requirements)
        return requirements if version.blank?

        requirements.merge(version: Regexp.union(Array.wrap(version).map(&:to_s)))
      end

      def build_path_from_pattern(pattern, anchor)
        return pattern.dup.insert(pattern.rindex('/') + 1, '?') if pattern.end_with?('*path')
        return pattern if anchor
        return "#{pattern}?*path" if pattern.end_with?('/')

        "#{pattern}/?*path"
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
