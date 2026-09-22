# frozen_string_literal: true

module Grape
  class Router
    def initialize
      @neutral_map = []
      @neutral_regexes = []
      # Plain hashes with no auto-vivifying default: a lookup for an HTTP method
      # that has no routes must not insert a key. `compile!` freezes them all,
      # so request-time reads never mutate shared state (see #match? / #rotation).
      @map = {}
      @optimized_map = {}
      @static_routes = {}
      # Per HTTP method, the greedy routes still worth trying once that method's
      # own routes have missed a path (see #compile_neighbour_map).
      @neighbour_map = {}
    end

    def compile!
      return if @compiled

      @union = resolve_capture_groups(Regexp.union(@neutral_regexes), @neutral_map)
      # Shared by the methods below: HEAD's routes mirror GET's, so their
      # buckets compile to the same unions.
      bucket_unions = {}
      # Compiled from the routes actually registered rather than from
      # Grape::HTTP_SUPPORTED_METHODS. A route declared with any other verb
      # (`route :purge, '/cache'`) is accepted at definition time and is
      # already collected into the resource's Allow header, so skipping it here
      # left it in @map but out of @optimized_map — the only map #match? reads.
      # The resource then advertised a method that could never be matched and
      # answered every request for it with 405.
      @map.each do |method, routes|
        optimized_map = routes.map.with_index { |route, index| route.to_regexp(index) }
        union = resolve_capture_groups(Regexp.union(optimized_map), routes)
        # Paired with the routes it was built from, so a match reads both
        # through a single lookup, and with the buckets that narrow those
        # routes by a path segment (nil when no segment splits them well).
        @optimized_map[method] = [union, routes, RouteBuckets.build(routes, optimized_map, bucket_unions)].freeze
        # Left out when no route spells out a path in full, so a request for
        # +method+ goes straight to the union rather than missing a lookup first.
        static_routes = static_routes_for(union, routes)
        @static_routes[method] = static_routes unless static_routes.empty?
      end
      compile_neighbour_map
      @neutral_regexes = nil
      @map.freeze
      @optimized_map.freeze
      @static_routes.freeze
      @neighbour_map.freeze
      # A route whose path holds a non-ASCII literal compiles to a UTF-8
      # regexp, which raises when matched against a binary string holding
      # non-ASCII bytes (see #utf8_path).
      @utf8_patterns = @union.fixed_encoding? || @optimized_map.each_value.any? { |union, _| union.fixed_encoding? }
      @compiled = true
    end

    def append(route)
      (@map[route.request_method] ||= []) << route
    end

    def associate_routes(greedy_route)
      @neutral_regexes << greedy_route.to_regexp(@neutral_map.length)
      @neutral_map << greedy_route
    end

    def call(env)
      request_method = env[Rack::REQUEST_METHOD]
      with_optimization(request_method) do
        input = Grape::Util::PathNormalizer.call(env[Rack::PATH_INFO])
        if @utf8_patterns && !input.ascii_only?
          input = utf8_path(input)
          next unless input
        end

        # Published on the env so the middleware the matched route runs -- the
        # path versioner above all -- reads the path this routed on instead of
        # normalizing PATH_INFO a second time.
        env[Grape::Env::GRAPE_NORMALIZED_PATH] = input
        transaction(input, request_method, env)
      end
    end

    def recognize_path(input)
      any = with_optimization do
        input = utf8_path(input) if @utf8_patterns && !input.ascii_only?
        greedy_match?(input) if input
      end
      return if any == default_response

      any.endpoint
    end

    DEFAULT_RESPONSE_HEADERS = Grape::Util::Header.new.merge('X-Cascade' => 'pass').freeze
    DEFAULT_RESPONSE_BODY = ['404 Not Found'].freeze

    private

    # +path+ tagged UTF-8 when its bytes are UTF-8, or nil when they are not.
    #
    # Rack hands PATH_INFO over binary, and a binary string holding non-ASCII
    # bytes raises Encoding::CompatibilityError when matched against a UTF-8
    # regexp -- so once one route held a non-ASCII literal (`/café/:id`),
    # every path carrying raw non-ASCII bytes raised, whichever route it was
    # meant for. Tagged UTF-8, such a path routes the way its percent-encoded
    # spelling does. Bytes that are not UTF-8 cannot be matched against these
    # routes at all, so the router answers them as a path nothing matched.
    #
    # A copy, so PATH_INFO itself stays binary as Rack requires.
    def utf8_path(path)
      utf8 = String.new(path, encoding: Encoding::UTF_8)
      utf8 if utf8.valid_encoding?
    end

    # Resolve +input+ against the compiled routes, in priority order:
    #
    # 1. the routes registered for +method+ — the compiled-union match first,
    #    then, when that route cascades, its siblings (see #rotation);
    # 2. the ANY (+'*'+) routes;
    # 3. the greedy neighbour, which answers 405 — and auto-OPTIONS, ahead of
    #    the ANY routes.
    #
    # Returns nil when nothing answered, leaving the caller to 404. A response
    # that cascades is never final: it is returned only once every later
    # candidate has declined too, so the caller (or a mounting app upstream)
    # can keep looking.
    def transaction(input, method, env)
      exact_route = nil
      response = nil
      if (static = @static_routes[method]&.[](input))
        exact_route, captures = static
        response = process_static_route(exact_route, captures, env)
      else
        union, routes, buckets = @optimized_map[method]
        if (bucket = buckets&.bucket_for(input))
          # A bucket numbers its groups its own way, so it hands over the
          # captures numbered for its own union along with the match.
          bucket.match(input) do |route, m, captures|
            exact_route = route
            response = process_route(route, input, env, m, captures)
          end
        else
          # Matched here rather than through #match? so the MatchData survives: the
          # route's path captures are groups of it (see Route#params_for).
          union&.match(input) do |m|
            exact_route = routes.detect { |route| m[route.regexp_capture_group] }
            response = process_route(exact_route, input, env, m, exact_route.union_captures)
          end
        end
      end
      return response if halt?(response)

      # A cascading route has only declined this request. Its siblings — the
      # routes sharing this path but differing in, say, version — must be
      # tried before falling back to the ANY routes and the greedy neighbour.
      # Skipped when nothing matched: the compiled union is the disjunction of
      # the same patterns #rotation walks, so a miss there is a miss here.
      cascaded = !response.nil?
      if cascaded
        response = rotation(input, method, env, exact_route)
        return response if response && !cascade?(response)
      end

      neighbours(input, method, env, response, cascaded)
    end

    # The ANY ('*') routes and the greedy neighbour, tried once the routes for
    # +method+ have declined. +cascaded+ says whether any of them matched: the
    # auto-OPTIONS and 405 answers are only right when none did.
    def neighbours(input, method, env, response, cascaded)
      # Only ever read while nothing for +method+ has matched, so once a route
      # has -- and cascaded -- there is no neighbour to look for.
      last_neighbor_route = neighbour_match?(input, method) unless cascaded

      # If last_neighbor_route exists and request method is OPTIONS,
      # return response by using #include_allow_header.
      return process_route(last_neighbor_route, input, env, include_allow_header: true) if !cascaded && method == Rack::OPTIONS && last_neighbor_route

      star_route = match?(input, '*')

      if star_route
        close_body(response) if response # superseded by the ANY route
        response = process_route(star_route, input, env)
        return response if halt?(response)

        cascaded ||= !response.nil?
      end

      return process_route(last_neighbor_route, input, env, include_allow_header: true) if !cascaded && last_neighbor_route

      response
    end

    # The routes registered for +method+ other than +exact_route+, tried in
    # registration order until one answers without cascading. Returns the last
    # response processed — a cascading one when every sibling declined, so the
    # caller can hand it back — or nil when no sibling matched.
    def rotation(input, method, env, exact_route)
      response = nil
      @map[method]&.each do |route|
        next if exact_route == route
        next unless route.match?(input)

        close_body(response) if response # the previous sibling cascaded
        response = process_route(route, input, env)
        break unless cascade?(response)
      end
      response
    end

    # Returns true if `response` should be returned as-is from the enclosing
    # transaction. Closes the body as a side effect when the response is
    # cascading so callers can safely try the next match.
    def halt?(response)
      return false unless response

      cascade = cascade?(response)
      close_body(response) if cascade
      !cascade
    end

    # Releases a response the router has decided not to return. Rack requires
    # every body it hands out to be closed, and a cascading candidate is
    # discarded as soon as a later one answers.
    def close_body(response)
      body = response[2]
      body.close if body.respond_to?(:close)
    end

    # Routing args are rebuilt for every attempt: when a route cascades
    # (X-Cascade pass), the next candidate must not observe the previous
    # attempt's +route_info+ or path captures.
    def process_route(route, input, env, match = nil, captures = nil, include_allow_header: false)
      # The path captures are the hash: +route_info+ is written into them
      # rather than merged in from a second one. +captures+ names the groups of
      # +match+ that hold them: the router's union numbers them one way, a
      # bucket's another.
      routing_args = route.params_for(input, match, captures) || {}
      routing_args[:route_info] = route
      env[Grape::Env::GRAPE_ROUTING_ARGS] = routing_args
      env[Grape::Env::GRAPE_ALLOWED_METHODS] = route.allow_header if include_allow_header
      route.call(env)
    end

    # {#process_route} for an entry of {#static_routes_for}. Its captures were
    # read when the table was built; each request gets its own copy of each,
    # the way it gets fresh strings out of a match.
    def process_static_route(route, captures, env)
      routing_args = captures&.transform_values(&:dup) || {}
      routing_args[:route_info] = route
      env[Grape::Env::GRAPE_ROUTING_ARGS] = routing_args
      route.call(env)
    end

    # A request for a path a route spells out in full -- no param in it, its
    # version filled in -- is answered from this table rather than by the
    # union. The union tries its alternatives one after another, and finding
    # which one matched scans every route ahead of it, so a request costs more
    # the later its route was registered; a Hash lookup does not.
    #
    # Each path is resolved here the way a request for it is, through the
    # union and the scan, so an entry holds whichever route answers it -- an
    # earlier route with a param where the path has a segment included -- and
    # the captures it hands over. Only paths worked out from the routes are
    # keys, so a client cannot grow the table, and a path that is not in it,
    # or whose captures are not all plain Strings, is matched as before.
    def static_routes_for(union, routes)
      routes.each_with_object({}) do |route, table|
        static_paths(route).each do |path|
          next if table.key?(path)

          union.match(path) do |m|
            matched = routes.detect { |candidate| m[candidate.regexp_capture_group] }
            captures = matched&.params_for(path, m)
            next unless matched && (captures.nil? || captures.each_value.all?(String))

            table[path] = [matched, captures.presence&.each_value(&:freeze)&.freeze].freeze
          end
        end
      end.freeze
    end

    STATIC_PATH_EXCLUDED = /[:*?(){}|\\%]/
    private_constant :STATIC_PATH_EXCLUDED

    # The request paths +route+ spells out in full: its origin, with each
    # version it declares filled in under path versioning. A path still
    # holding pattern syntax or a '%', or one the normalizer would rewrite, is
    # left out, since no request routes on it spelled that way. This only
    # picks the paths worth resolving; what answers them is up to the union.
    def static_paths(route)
      origin = route.origin
      version_segment = Grape::Router::Pattern::Path::VERSION_SEGMENT
      paths = origin.include?(version_segment) ? Array(route.version).map { |version| origin.sub(version_segment, version.to_s) } : [origin]
      paths.select { |path| !path.match?(STATIC_PATH_EXCLUDED) && Grape::Util::PathNormalizer.call(path) == path }
    end

    # Tells each route the number of the group it ended up as in +union+. The
    # numbering is a property of the union rather than of the route's own
    # pattern -- every route ahead of it contributes however many groups its
    # pattern declares -- so it can only be resolved once the union is built.
    # Returns the union, so a caller can assign it in one expression.
    def resolve_capture_groups(union, routes)
      named_captures = union.named_captures
      routes.each { |route| route.resolve_capture_group!(named_captures) }
      union
    end

    def with_optimization(request_method = nil)
      compile!
      yield || default_response(request_method)
    end

    # The 404 answered when nothing matched. A HEAD request gets it without a
    # body, as Rack requires: every endpoint strips its own with Rack::Head,
    # but no endpoint answers a path nothing matched.
    def default_response(request_method = nil)
      body = request_method == Rack::HEAD ? [] : DEFAULT_RESPONSE_BODY.dup
      [404, DEFAULT_RESPONSE_HEADERS.dup, body]
    end

    # Which alternative of the union matched is answered by scanning one group
    # per registered route, so on an API with many of them that scan is what a
    # request costs. The groups are indexed by number rather than by name: a
    # name sends MatchData through the pattern's name table on every lookup,
    # a number indexes the match region directly.
    def match?(input, method)
      union, routes = @optimized_map[method]
      union&.match(input) { |m| routes.detect { |route| m[route.regexp_capture_group] } }
    end

    def greedy_match?(input)
      @union.match(input) { |m| @neutral_map.detect { |route| m[route.regexp_capture_group] } }
    end

    # The greedy route for +input+ once the routes for +method+ have all missed
    # it, from the ones #compile_neighbour_map left to try. A method with no
    # routes of its own covers no path, so it still walks the whole of @union.
    def neighbour_match?(input, method)
      return greedy_match?(input) unless @map.key?(method)

      union, routes, groups = @neighbour_map[method]
      union&.match(input) do |m|
        routes[groups.index { |group| m[group] }]
      end
    end

    # After a miss, #neighbours looks for a greedy route to answer 405 with.
    # Walking the whole of @union for it would cost a 404 a second walk over
    # every path, and most of that walk cannot succeed: a greedy route shares
    # its pattern with the routes it was collected from (see
    # API::Instance#collect_route_config_per_pattern), so once the union for
    # +method+ has missed a path, the greedy route of every path +method+ has a
    # route on has missed it too. What is left to try is the paths +method+ has
    # no route on -- in an API where every path answers GET, none at all for a
    # GET.
    #
    # Built from the same members as @union, in the same order, so a path
    # resolves to the same greedy route either way. Methods that leave the same
    # paths uncovered -- PUT and DELETE on a member, say -- share one union.
    def compile_neighbour_map
      unions = {}
      @map.each do |method, routes|
        covered = routes.to_set(&:pattern_regexp)
        uncovered = @neutral_map.each_index.reject { |index| covered.include?(@neutral_map[index].pattern_regexp) }
        @neighbour_map[method] = unions[uncovered] ||= neighbour_union(uncovered) unless uncovered.empty?
      end
    end

    # The union of the greedy routes at +indices+ of @neutral_map, those
    # routes, and the group each of them occupies in the union: a subset of
    # @union numbers its groups differently, so the ones
    # #resolve_capture_groups recorded do not apply. Routes and groups are
    # parallel Arrays for #neighbour_match? to walk with Array#index, as
    # Enumerable#find over a Hash allocates on every call.
    def neighbour_union(indices)
      union = Regexp.union(@neutral_regexes.values_at(*indices))
      named_captures = union.named_captures
      routes = @neutral_map.values_at(*indices).freeze
      groups = routes.map { |route| named_captures.fetch(route.regexp_capture_index).first }.freeze
      [union, routes, groups].freeze
    end

    def cascade?(response)
      response && response[1]['X-Cascade'] == 'pass'
    end
  end
end
