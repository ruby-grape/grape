# frozen_string_literal: true

module Grape
  class Router
    def initialize
      @neutral_map = []
      @neutral_regexes = []
      # Plain hashes with no auto-vivifying default: a lookup for an HTTP method
      # that has no routes must not insert a key. `compile!` freezes them all,
      # so request-time reads never mutate shared state (see #star_route_for / #rotation).
      @map = {}
      @optimized_map = {}
      # Per HTTP method, the allowed-methods routes still worth trying once that
      # method's own routes have missed a path (see #compile_neighbour_map).
      @neighbour_map = {}
    end

    def compile!
      return if @compiled

      @union = resolve_capture_groups(Regexp.union(@neutral_regexes), @neutral_map)
      compile_optimized_map
      compile_neighbour_map
      @neutral_regexes = nil
      @map.freeze
      @optimized_map.freeze
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

    def associate_routes(allowed_methods_route)
      @neutral_regexes << allowed_methods_route.to_regexp(@neutral_map.length)
      @neutral_map << allowed_methods_route
    end

    def call(env)
      request_method = env[Rack::REQUEST_METHOD]
      with_optimization do
        input = Grape::Util::PathNormalizer.call(env[Rack::PATH_INFO])
        if @utf8_patterns && !input.ascii_only?
          input = utf8_path(input)
          next unless input
        end

        # Published on the env so the middleware the matched route runs -- the
        # path versioner above all -- reads the path this routed on instead of
        # normalizing PATH_INFO a second time.
        env[Grape::Env::GRAPE_NORMALIZED_PATH] = input
        dispatch(input, request_method, env)
      end
    end

    def recognize_path(input)
      any = with_optimization do
        input = utf8_path(input) if @utf8_patterns && !input.ascii_only?
        # A path that is not valid UTF-8 comes back nil and matches nothing.
        allowed_methods_route_for(input)
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
    # 3. the allowed-methods route, which answers 405 — and auto-OPTIONS, ahead
    #    of the ANY routes.
    #
    # Returns nil when nothing answered, leaving the caller to 404. A response
    # that cascades is never final, whatever its status: the route has declined,
    # so its body is closed and the caller's 404 stands in for it. That 404 still
    # carries X-Cascade, so a mounting app upstream can keep looking.
    def dispatch(input, method, env)
      union, routes, buckets, static_routes = @optimized_map[method]
      if (static = static_routes&.[](input))
        exact_route, captures = static
        settle(input, method, env, process_static_route(exact_route, captures, env), exact_route)
      elsif (bucket = buckets&.bucket_for(input))
        dispatch_to_bucket(bucket, input, method, env)
      else
        dispatch_to_union(union, routes, input, method, env)
      end
    end

    # #dispatch for a path a bucket narrowed the routes for. A bucket
    # numbers its groups its own way, so it hands over the captures numbered
    # for its own union along with the match.
    def dispatch_to_bucket(bucket, input, method, env)
      exact_route = nil
      response = bucket.match(input) do |route, m, captures|
        exact_route = route
        process_route(route, input, env, m, captures)
      end
      settle(input, method, env, response, exact_route)
    end

    # #dispatch for a path matched against all the routes for +method+. The
    # route comes out of the MatchData here, rather than from a lookup answering
    # only the route, as its path captures are groups of it (see
    # Route#params_for).
    def dispatch_to_union(union, routes, input, method, env)
      exact_route = nil
      response = union&.match(input) do |m|
        exact_route = matched_route(routes, m)
        process_route(exact_route, input, env, m, exact_route.union_captures)
      end
      settle(input, method, env, response, exact_route)
    end

    # What #dispatch answers once +exact_route+ answered with +response+: that
    # response, unless it cascades. No route for +method+ matching (+response+ is
    # nil) and one declining (+response+ cascades) leave different things to try.
    def settle(input, method, env, response, exact_route)
      return after_miss(input, method, env) unless response

      final_response(response) || after_cascade(input, method, env, exact_route)
    end

    # No route for +method+ matched, so the path may still answer another method.
    # #rotation has nothing to add: the compiled union is the disjunction of the
    # same patterns it walks, so a miss there is a miss here.
    def after_miss(input, method, env)
      allowed_methods_route = neighbour_route_for(input, method)
      return process_route(allowed_methods_route, input, env, include_allow_header: true) if allowed_methods_route && method == Rack::OPTIONS

      star_route = star_route_for(input)
      # An ANY route that declined still matched, so no 405 follows it.
      return final_response(process_route(star_route, input, env)) if star_route

      process_route(allowed_methods_route, input, env, include_allow_header: true) if allowed_methods_route
    end

    # A route for +method+ matched and declined this request. Its siblings -- the
    # routes sharing this path but differing in, say, version -- are tried before
    # the ANY routes. The auto-OPTIONS and 405 answers are not: a route matched,
    # so the method is allowed.
    def after_cascade(input, method, env, exact_route)
      answer = rotation(input, method, env, exact_route)
      return answer if answer

      star_route = star_route_for(input)
      final_response(process_route(star_route, input, env)) if star_route
    end

    # The routes registered for +method+ other than +exact_route+, tried in
    # registration order until one answers without cascading. Returns that
    # answer, or nil when every sibling declined or none matched.
    def rotation(input, method, env, exact_route)
      answer = nil
      @map[method].each do |route|
        next if exact_route == route
        next unless route.match?(input)

        answer = final_response(process_route(route, input, env))
        break if answer
      end
      answer
    end

    # +response+, or nil once it has cascaded: the route has declined, so its
    # body is closed and whatever answers next stands in for it.
    def final_response(response)
      return response unless cascade?(response)

      close_body(response)
      nil
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

          entry = static_route_entry(union, routes, path)
          table[path] = entry if entry
        end
      end.freeze
    end

    # The route a request for +path+ resolves to and the captures it hands
    # over, frozen for every such request to share; nil when a capture is not
    # a String.
    def static_route_entry(union, routes, path)
      union.match(path) do |m|
        matched = matched_route(routes, m)
        captures = matched.params_for(path, m)
        # Only a String is frozen whole below; any other capture would be
        # shared across requests with its insides open to change.
        next unless captures.nil? || captures.each_value.all?(String)

        [matched, captures.presence&.each_value(&:freeze)&.freeze].freeze
      end
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

    def with_optimization
      compile!
      yield || default_response
    end

    # The 404 answered when nothing matched. The Rack::Head the API wraps
    # around the router strips its body from a HEAD request.
    def default_response
      [404, DEFAULT_RESPONSE_HEADERS.dup, DEFAULT_RESPONSE_BODY.dup]
    end

    def star_route_for(input)
      union, routes = @optimized_map['*']
      union&.match(input) { |m| matched_route(routes, m) }
    end

    def allowed_methods_route_for(input)
      @union.match(input) { |m| matched_route(@neutral_map, m) }
    end

    # The route of +routes+ whose alternative of their union produced +match+.
    # Which one that was is answered by scanning one group per registered route,
    # so on an API with many of them that scan is what a request costs. The groups
    # are indexed by number rather than by name: a name sends MatchData through
    # the pattern's name table on every lookup, a number indexes the match region
    # directly.
    def matched_route(routes, match)
      routes.detect { |route| match[route.regexp_capture_group] }
    end

    # The allowed-methods route for +input+ once the routes for +method+ have all
    # missed it, from the ones #compile_neighbour_map left to try. A method with
    # no routes of its own covers no path, so it still walks the whole of @union.
    def neighbour_route_for(input, method)
      return allowed_methods_route_for(input) unless @map.key?(method)

      union, routes, groups = @neighbour_map[method]
      union&.match(input) do |m|
        routes[groups.index { |group| m[group] }]
      end
    end

    # Compiled from the routes actually registered rather than from
    # Grape::HTTP_SUPPORTED_METHODS. A route declared with any other verb
    # (`route :purge, '/cache'`) is accepted at definition time and is
    # already collected into the resource's Allow header, so skipping it here
    # left it in @map but out of @optimized_map — the only map #match? reads.
    # The resource then advertised a method that could never be matched and
    # answered every request for it with 405.
    def compile_optimized_map
      # Shared by the methods below: HEAD's routes mirror GET's, so their
      # buckets compile to the same unions.
      bucket_unions = {}
      @map.each do |method, routes|
        @optimized_map[method] = optimized_routes(routes, bucket_unions)
      end
    end

    # The union of +routes+, paired with the routes it was built from, so a
    # request reads everything it can be matched with through a single
    # lookup: the buckets that narrow those routes by a path segment (nil
    # when no segment splits them well), and the table of the paths they
    # spell out in full -- nil when none does, so a request for their method
    # goes straight to the union rather than missing a lookup first.
    def optimized_routes(routes, bucket_unions)
      regexps = routes.map.with_index { |route, index| route.to_regexp(index) }
      union = resolve_capture_groups(Regexp.union(regexps), routes)
      static_routes = static_routes_for(union, routes)
      [union, routes, RouteBuckets.build(routes, regexps, bucket_unions), (static_routes unless static_routes.empty?)].freeze
    end

    # #after_miss looks for an allowed-methods route to answer 405 with. Walking
    # the whole of @union for it would cost a 404 a second walk over every path,
    # and most of that walk cannot succeed: an allowed-methods route shares its
    # pattern with the routes it was collected from (see
    # API::Instance#collect_route_config_per_pattern), so once the union for
    # +method+ has missed a path, the allowed-methods route of every path
    # +method+ has a route on has missed it too. What is left to try is the paths
    # +method+ has no route on -- in an API where every path answers GET, none at
    # all for a GET.
    #
    # Built from the same members as @union, in the same order, so a path
    # resolves to the same allowed-methods route either way. Methods that leave
    # the same paths uncovered -- PUT and DELETE on a member, say -- share one
    # union.
    def compile_neighbour_map
      unions = {}
      @map.each do |method, routes|
        covered = routes.to_set(&:pattern_regexp)
        uncovered = @neutral_map.each_index.reject { |index| covered.include?(@neutral_map[index].pattern_regexp) }
        @neighbour_map[method] = unions[uncovered] ||= neighbour_union(uncovered) unless uncovered.empty?
      end
    end

    # The union of the allowed-methods routes at +indices+ of @neutral_map, those
    # routes, and the group each of them occupies in the union: a subset of
    # @union numbers its groups differently, so the ones
    # #resolve_capture_groups recorded do not apply. Routes and groups are
    # parallel Arrays for #neighbour_route_for to walk with Array#index, as
    # Enumerable#find over a Hash allocates on every call.
    def neighbour_union(indices)
      union = Regexp.union(@neutral_regexes.values_at(*indices))
      named_captures = union.named_captures
      routes = @neutral_map.values_at(*indices).freeze
      groups = routes.map { |route| named_captures.fetch(route.regexp_capture_index).first }.freeze
      [union, routes, groups].freeze
    end

    def cascade?(response)
      response[1]['X-Cascade'] == 'pass'
    end
  end
end
