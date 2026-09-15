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
    class RouteBuckets
      # The routes one segment value can reach, with the number each one's
      # group has in +union+: a route sits in several buckets, at a different
      # position in each, so the numbers cannot be kept on the route.
      class Bucket
        def initialize(union, routes, groups)
          @union = union
          @routes = routes
          @groups = groups
          freeze
        end

        def match(input)
          @union&.match(input) do |m|
            index = @groups.index { |group| m[group] }
            @routes[index] if index
          end
        end
      end

      NONE = Bucket.new(nil, [].freeze, [].freeze)
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
        def build(routes, regexps, unions)
          return if routes.size < MINIMUM_ROUTES

          segments = routes.map { |route| route.origin.split('/') }
          depth = segments.map(&:size).max
          candidates = (1...depth).map do |position|
            [position, routes.each_with_index.map { |route, index| key_for(route, segments[index], position) }]
          end
          position, keys = candidates.min_by { |_, route_keys| cost(route_keys) }
          return unless position && cost(keys) <= routes.size / 2

          new(position, routes, regexps, keys, unions)
        end

        private

        # The literal +route+ requires at segment +position+, or nil when it
        # cannot be told apart by that segment.
        def key_for(route, segments, position)
          return if segments.size <= position
          return unless segments[1...position].all? { |segment| single_segment?(route, segment) }

          key = segments[position]
          return unless key.match?(KEY_SEGMENT) && key.ascii_only?
          # An unanchored route's trailing '/?*path' can run on into this segment.
          return if position == segments.size - 1 && !route.anchor

          key
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
        ungrouped = keys.each_index.select { |index| keys[index].nil? }
        grouped = keys.each_index.reject { |index| keys[index].nil? }.group_by { |index| keys[index] }
        @buckets = grouped.transform_values { |indices| bucket(routes, regexps, (indices + ungrouped).sort, unions) }.freeze
        @fallback = ungrouped.empty? ? NONE : bucket(routes, regexps, ungrouped, unions)
        freeze
      end

      # The bucket for +input+, or nil when it has to go through the full union.
      def bucket_for(input)
        return if input.match?(FULL_UNION_INPUT)

        key = segment_key(input)
        (key && @buckets[key]) || @fallback
      end

      private

      def bucket(routes, regexps, indices, unions)
        alternatives = regexps.values_at(*indices).freeze
        members = routes.values_at(*indices).freeze
        union, groups = unions[alternatives] ||= compile_union(alternatives, members)
        Bucket.new(union, members, groups)
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
