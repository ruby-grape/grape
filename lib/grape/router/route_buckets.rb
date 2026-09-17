# frozen_string_literal: true

module Grape
  class Router
    # Narrows the routes a request is matched against to the ones that can
    # match its path, by one literal path segment.
    #
    # A route that spells out a literal at segment +k+ of its path -- with
    # every segment ahead of it a literal or a lone +:param+ that cannot span
    # a '/' -- matches only paths whose segment +k+ is that literal. Grouping
    # the routes by it, and keeping every route that cannot be grouped in each
    # group, gives each group the routes that could match a path with that
    # segment, still in registration order, so the first of them to match is
    # the route the full union would have picked.
    #
    # Mustermann lets a literal character match its percent-encoding, and a
    # route's pattern ends in \Z, which also matches before a trailing
    # newline, so a path holding either is left to the full union.
    #
    # For example, a method with these routes, in registration order:
    #
    #   /users  /users/:id  /users/:id/posts  /posts  /posts/:id
    #   /comments/:id  /tags/:name  /:slug
    #
    # is split by segment 1, which names every route but +/:slug+:
    #
    #   "users"    => /users, /users/:id, /users/:id/posts, /:slug
    #   "posts"    => /posts, /posts/:id, /:slug
    #   "comments" => /comments/:id, /:slug
    #   "tags"     => /tags/:name, /:slug
    #   fallback   => /:slug
    #
    # A request for +/users/42+ is matched against the four routes under
    # "users" instead of all eight, +/about+ names no bucket and is matched
    # against the fallback, and +/users%2F42+ goes to the full union.
    class RouteBuckets
      # The routes one segment value can reach, with the number each one's
      # group has in +union+: a route sits in several buckets, at a different
      # position in each, so the numbers cannot be kept on the route.
      class Bucket
        def initialize(union, routes, groups, captures)
          @union = union
          @routes = routes
          @groups = groups
          @captures = captures
          freeze
        end

        # Yields the route +input+ matched, the match, and that route's
        # captures numbered for this union -- nil when a match cannot stand in
        # for what Mustermann returns. Yields nothing when no route here
        # matches.
        def match(input)
          @union&.match(input) do |m|
            index = @groups.index { |group| m[group] }
            yield(@routes[index], m, @captures[index]) if index
          end
        end
      end

      NONE = Bucket.new(nil, [].freeze, [].freeze, [].freeze)
      FULL_UNION_INPUT = /[%\n]/
      # A segment ahead of the key: plain characters, or one +:param+.
      LITERAL_SEGMENT = /\A[^:*?(){}|\\%]+\z/
      CAPTURE_SEGMENT = /\A:(\w+)\z/
      # The key itself is compared with a slice of the path cut at the first
      # '.', so it holds no '.', and nothing a path could spell differently.
      KEY_SEGMENT = /\A[^:*?(){}|\\%.+\s]+\z/
      # Below this many routes the full union is already cheap to walk, and
      # the extra unions would only lengthen boot.
      MINIMUM_ROUTES = 8
      private_constant :Bucket, :NONE, :FULL_UNION_INPUT, :LITERAL_SEGMENT, :CAPTURE_SEGMENT, :KEY_SEGMENT, :MINIMUM_ROUTES

      class << self
        # Buckets for +routes+ (with +regexps+, their union alternatives), or
        # nil when no segment splits them well enough to be worth the unions.
        # +unions+ is shared by a router's methods, so a bucket whose
        # alternatives another method already compiled -- the HEAD routes
        # mirroring GET's -- reuses that union.
        #
        # Every segment position is tried, and the one leaving the fewest
        # routes to match wins. For the routes in the class example:
        #
        #   position 1: users x3, posts x2, comments, tags, nil  cost 1 + 3 = 4
        #   position 2: nil for all eight                        cost 8
        #   position 3: posts for /users/:id/posts, nil for 7    cost 7 + 1 = 8
        #
        # Position 1 wins, and a cost of 4 is within half of the 8 routes, so
        # the buckets are built; at 5 they would not be.
        def build(routes, regexps, unions)
          return if routes.size < MINIMUM_ROUTES

          segments = routes.map { |route| route.origin.split('/') }
          depth = segments.map(&:size).max
          keys_by_position = Array.new(depth) { Array.new(routes.size) }
          routes.each_with_index { |route, index| fill_keys(keys_by_position, index, route, segments[index]) }
          candidates = (1...depth).map { |position| [position, keys_by_position[position]] }
          position, keys = candidates.min_by { |_, route_keys| cost(route_keys) }
          return unless position && cost(keys) <= routes.size / 2

          new(position, routes, regexps, keys, unions)
        end

        private

        # Writes into +keys_by_position+, at +index+, the literal +route+
        # requires at each segment position, leaving nil where that segment
        # cannot tell it apart. One walk over +segments+: a segment that does
        # not span exactly one path segment ends it, as no position past that
        # segment can tell the route apart either.
        def fill_keys(keys_by_position, index, route, segments)
          last = segments.size - 1
          position = 1
          while position <= last
            segment = segments[position]
            keys_by_position[position][index] = segment if key?(route, segment, position == last)
            return unless single_segment?(route, segment)

            position += 1
          end
        end

        def key?(route, segment, last_segment)
          return false unless segment.match?(KEY_SEGMENT) && segment.ascii_only?

          # An unanchored route's trailing '/?*path' can run on into this segment.
          !last_segment || route.anchor
        end

        def single_segment?(route, segment)
          return true if segment.match?(LITERAL_SEGMENT)

          name = segment[CAPTURE_SEGMENT, 1]
          return false unless name
          return Array(route.version).none? { |version| version.to_s.include?('/') } if name == 'version'

          requirements = route.requirements
          !(requirements && (requirements.key?(name.to_sym) || requirements.key?(name)))
        end

        # The most routes one request can still be matched against.
        def cost(keys)
          keys.count(nil) + (keys.compact.tally.values.max || 0)
        end
      end

      def initialize(position, routes, regexps, keys, unions)
        @position = position
        ungrouped, grouped = split_indices(keys)
        # Every bucket holds the routes no segment tells apart, so none can be
        # built before the whole of +ungrouped+ is known.
        grouped.transform_values! { |indices| bucket(routes, regexps, (indices + ungrouped).sort!, unions) }
        @buckets = grouped.freeze
        @fallback = ungrouped.empty? ? NONE : bucket(routes, regexps, ungrouped, unions)
        freeze
      end

      # The bucket for +input+, or nil when it has to go through the full union.
      # With the class example's buckets:
      #
      #   /users/42, /users.json, /users/42.json  => "users"
      #   /about, /                                => the fallback
      #   /users%2F42, "/users\n"                  => nil
      def bucket_for(input)
        return if input.match?(FULL_UNION_INPUT)

        key = segment_key(input)
        (key && @buckets[key]) || @fallback
      end

      private

      # The indices of the routes no key names, and the indices each key does
      # name, in one pass over +keys+ -- +keys[n]+ being the key of the route
      # at +n+, or nil when no segment tells that route apart.
      def split_indices(keys)
        ungrouped = []
        grouped = {}
        keys.each_with_index do |key, index|
          next ungrouped << index if key.nil?

          (grouped[key] ||= []) << index
        end
        [ungrouped, grouped]
      end

      def bucket(routes, regexps, indices, unions)
        alternatives = regexps.values_at(*indices).freeze
        members = routes.values_at(*indices).freeze
        union, groups = unions[alternatives] ||= compile_union(alternatives, members)
        # A member sits at a different group here than it does in the router's
        # union, which is what its own captures are numbered for.
        captures = members.map.with_index { |route, index| route.union_captures_at(groups[index]) }.freeze
        Bucket.new(union, members, groups, captures)
      end

      # The union of +alternatives+ and the group each of +members+ has in it.
      # Each alternative names its group after its route's position, so equal
      # alternatives spell out the same union with the same groups, whichever
      # method's routes they came from.
      def compile_union(alternatives, members)
        union = Regexp.union(alternatives)
        named_captures = union.named_captures
        [union, members.map { |route| named_captures.fetch(route.regexp_capture_index).first }.freeze].freeze
      end

      # Segment +@position+ of +input+, cut at its first '.'.
      def segment_key(input)
        start = 0
        @position.times do
          start = input.index('/', start)
          return unless start

          start += 1
        end
        stop = input.index('/', start) || input.length
        dot = input.index('.', start)
        stop = dot if dot && dot < stop
        input[start, stop - start]
      end
    end
  end
end
