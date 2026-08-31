# frozen_string_literal: true

module Grape
  class Router
    # @deprecated Use {Grape::Util::PathNormalizer.call} instead.
    def self.normalize_path(path)
      Grape.deprecator.warn(
        '`Grape::Router.normalize_path` is deprecated. Use `Grape::Util::PathNormalizer.call` instead.'
      )
      Grape::Util::PathNormalizer.call(path)
    end

    def initialize
      @neutral_map = []
      @neutral_regexes = []
      # Plain hashes with no auto-vivifying default: a lookup for an HTTP method
      # that has no routes must not insert a key. `compile!` freezes both maps,
      # so request-time reads never mutate shared state (see #match? / #rotation).
      @map = {}
      @optimized_map = {}
    end

    def compile!
      return if @compiled

      @union = Regexp.union(@neutral_regexes)
      @neutral_regexes = nil
      (Grape::HTTP_SUPPORTED_METHODS + ['*']).each do |method|
        next unless @map.key?(method)

        routes = @map[method]
        optimized_map = routes.map.with_index { |route, index| route.to_regexp(index) }
        @optimized_map[method] = Regexp.union(optimized_map)
      end
      @map.freeze
      @optimized_map.freeze
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
      with_optimization do
        input = Grape::Util::PathNormalizer.call(env[Rack::PATH_INFO])
        transaction(input, env[Rack::REQUEST_METHOD], env)
      end
    end

    def recognize_path(input)
      any = with_optimization { greedy_match?(input) }
      return if any == default_response

      any.endpoint
    end

    DEFAULT_RESPONSE_HEADERS = Grape::Util::Header.new.merge('X-Cascade' => 'pass').freeze
    DEFAULT_RESPONSE_BODY = ['404 Not Found'].freeze

    private

    # Resolve +input+ against the compiled routes, in priority order:
    #
    # 1. the routes registered for +method+ — the compiled-union match first,
    #    then, when that route cascades, its siblings (see #rotation);
    # 2. the ANY (+'*'+) routes;
    # 3. the greedy neighbour, which answers auto-OPTIONS and 405.
    #
    # Returns nil when nothing answered, leaving the caller to 404. A response
    # that cascades is never final: it is returned only once every later
    # candidate has declined too, so the caller (or a mounting app upstream)
    # can keep looking.
    def transaction(input, method, env)
      exact_route = match?(input, method)
      response = process_route(exact_route, input, env) if exact_route
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

      last_neighbor_route = greedy_match?(input)

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
    def process_route(route, input, env, include_allow_header: false)
      # The path captures are the hash: +route_info+ is written into them
      # rather than merged in from a second one.
      routing_args = route.params_for(input) || {}
      routing_args[:route_info] = route
      env[Grape::Env::GRAPE_ROUTING_ARGS] = routing_args
      env[Grape::Env::GRAPE_ALLOWED_METHODS] = route.allow_header if include_allow_header
      route.call(env)
    end

    def with_optimization
      compile!
      yield || default_response
    end

    def default_response
      [404, DEFAULT_RESPONSE_HEADERS.dup, DEFAULT_RESPONSE_BODY.dup]
    end

    def match?(input, method)
      @optimized_map[method]&.match(input) { |m| @map[method].detect { |route| m[route.regexp_capture_index] } }
    end

    def greedy_match?(input)
      @union.match(input) { |m| @neutral_map.detect { |route| m[route.regexp_capture_index] } }
    end

    def cascade?(response)
      response && response[1]['X-Cascade'] == 'pass'
    end
  end
end
