# frozen_string_literal: true

module Grape
  class Router
    # Derives, from a compiled route union, an equivalent matcher for the
    # inputs that carry no <tt>%</tt>.
    #
    # Grape compiles every route pattern with Mustermann's +uri_decode: true+,
    # which expands each *literal* character of a path into an alternation with
    # its percent-encodings -- +/resource+ becomes
    # <tt>\/(?:r|%72)(?:e|%65)(?:s|%73)(?:o|%6F|%6f)…</tt> -- so that
    # +/a%2Eb+ still reaches a route declared as +/a.b+. The router's union is
    # the disjunction of those patterns, so the expansion is paid on every
    # request: it roughly doubles the compiled source, and on a union of a few
    # hundred routes it costs both the successful match and -- by hiding the
    # literal prefix every branch starts with -- the far cheaper failure that
    # Onigmo could otherwise reach.
    #
    # An input holding no +%+ cannot take any of those alternatives, so for it
    # the union without them accepts exactly the same strings, by the same path
    # through the regexp, capturing exactly the same substrings. This module
    # removes them.
    #
    # The surgery is done on the union's source rather than by recompiling each
    # pattern with +uri_decode: false+, for two reasons: it is an order of
    # magnitude cheaper at boot (one +gsub+ and one +Regexp.new+ for the whole
    # union, against a fresh Mustermann parse per route), and it is the more
    # faithful transformation. +uri_decode: false+ also drops the +\++ branch
    # that lets a plus match a literal space in the path, which would make a
    # +%+-free request miss a route the decode-aware union matches; removing
    # only the +%XX+ branches keeps it.
    module PlainUnion
      # One alternative of a compiled alternation: escapes count as one unit,
      # and no alternative of Mustermann's character expansion contains a
      # bracket or a bar of its own.
      ALTERNATIVE = /(?:\\.|[^\\()|])+/

      # A whole <tt>(?:a|b|…)</tt> alternation, the shape +Compiler#encoded+
      # emits for a path literal.
      ALTERNATION = /\(\?:#{ALTERNATIVE}(?:\|#{ALTERNATIVE})+\)/

      # Regions to step over rather than rewrite, so that an alternation is only
      # ever recognised where one can actually occur. A +requirements+ Regexp is
      # inserted into the pattern verbatim, and inside a character class
      # <tt>(?:</tt> and <tt>|</tt> are literal characters -- rewriting
      # <tt>[(?:a|%41)]</tt> would drop +|+, +%+, +4+ and +1+ from the set it
      # matches, which is a change a '%'-free request would see. Consuming
      # escapes as units keeps an escaped bracket from opening a class.
      SKIPPED = /\\.|\[(?:\\.|[^\]\\])*\]/

      # One pass over the source: a region to step over, or an alternation to
      # rewrite. Ordered so a character class is consumed before anything
      # inside it can be recognised as an alternation of its own.
      SCANNER = /#{SKIPPED}|#{ALTERNATION}/

      # An alternative that is only a percent-encoded octet.
      PERCENT_ENCODED = /\A%\h\h\z/

      # An alternative that is a single character, escaped or not -- everything
      # +Compiler#encoded+ emits, and the only shape whose group is safe to drop
      # (see #strip_percent_alternatives).
      SINGLE_CHARACTER = /\A(?:\\.|[^\\])\z/

      class << self
        # @param union [Regexp] the compiled union of every route's pattern
        # @return [Regexp] the same union with the percent-encoded alternatives
        #   of its path literals removed, or +union+ itself when there is
        #   nothing to remove or the result would not be a faithful stand-in
        def build(union)
          source = strip_percent_alternatives(union.source)
          return union if source == union.source

          plain = Regexp.new(source)
          # Route matching reads the union's groups by number
          # (see BaseRoute#union_captures), so a stand-in that numbered or
          # named them differently would hand the wrong substrings to the
          # endpoint. Nothing observed does this -- the alternatives dropped
          # here are non-capturing -- but the check is one comparison at boot
          # against silently wrong params, and falling back to the decode-aware
          # union only costs speed.
          plain.named_captures == union.named_captures ? plain : union
        rescue RegexpError
          union
        end

        private

        # Rewrites <tt>(?:o|%6F|%6f)</tt> to <tt>o</tt> and
        # <tt>(?: |%20|\+|%2B)</tt> to <tt>(?: |\+)</tt>, and leaves every other
        # alternation -- a +requirements+ Regexp, the declared-versions union --
        # untouched.
        #
        # Replaced through a Hash rather than a block: a union repeats the same
        # few dozen expansions thousands of times over, and memoizing their
        # rewrites is an order of magnitude faster than recomputing one per
        # match.
        def strip_percent_alternatives(source)
          rewrites = Hash.new { |memo, region| memo[region] = rewrite(region) }
          source.gsub(SCANNER, rewrites)
        end

        # @param region [String] one {SCANNER} match: an alternation to rewrite,
        #   or an escape or character class to hand back untouched
        def rewrite(region)
          # A skipped region starts with a backslash or a bracket, so this tells
          # the two apart without a second capture group.
          return region unless region.start_with?('(?:')

          # Scanned rather than split on '|': an alternative can be an escaped
          # bar of its own ('/a\\|b' compiles to <tt>(?:\\||%7C|%7c)</tt>),
          # which a split would cut in half.
          alternatives = region[3..-2].scan(ALTERNATIVE)
          kept = alternatives.grep_v(PERCENT_ENCODED)
          return region if kept.size == alternatives.size || kept.empty?

          # The group is only dropped around a lone *character*: a quantifier can
          # follow the alternation, and it binds to the group, not to what the
          # group holds. A path literal is always a single character, so the case
          # that matters keeps its bare form -- which is what lets Onigmo read a
          # literal prefix off the union again. A longer alternative can only
          # come from a +requirements+ Regexp, where <tt>(?:ab|%41)+</tt> must
          # not become <tt>ab+</tt>.
          return kept.first if kept.size == 1 && kept.first.match?(SINGLE_CHARACTER)

          "(?:#{kept.join('|')})"
        end
      end
    end
  end
end
