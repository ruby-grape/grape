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
      @map = Hash.new { |hash, key| hash[key] = [] }
      @optimized_map = Hash.new { |hash, key| hash[key] = // }
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
      @compiled = true
    end

    def append(route)
      @map[route.request_method] << route
    end

    def associate_routes(greedy_route)
      @neutral_regexes << greedy_route.to_regexp(@neutral_map.length)
      @neutral_map << greedy_route
    end

    def call(env)
      with_optimization do
        input = Grape::Util::PathNormalizer.call(env[Rack::PATH_INFO])
        method = env[Rack::REQUEST_METHOD]
        response, route = identity(input, method, env)
        response || rotation(input, method, env, route)
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

    def identity(input, method, env)
      route = nil
      response = transaction(input, method, env) do
        route = match?(input, method)
        process_route(route, input, env) if route
      end
      [response, route]
    end

    def rotation(input, method, env, exact_route)
      response = nil
      @map[method].each do |route|
        next if exact_route == route
        next unless route.match?(input)

        response = process_route(route, input, env)
        break unless cascade?(response)
      end
      response
    end

    def transaction(input, method, env)
      response = yield
      return response if halt?(response)

      last_response_cascade = !response.nil?
      last_neighbor_route = greedy_match?(input)

      # If last_neighbor_route exists and request method is OPTIONS,
      # return response by using #include_allow_header.
      return process_route(last_neighbor_route, input, env, include_allow_header: true) if !last_response_cascade && method == Rack::OPTIONS && last_neighbor_route

      route = match?(input, '*')

      return last_neighbor_route.call(env) if last_neighbor_route && last_response_cascade && route

      if route
        route_response = process_route(route, input, env)
        return route_response if halt?(route_response)

        last_response_cascade = !route_response.nil?
      end

      return process_route(last_neighbor_route, input, env, include_allow_header: true) if !last_response_cascade && last_neighbor_route

      nil
    end

    # Returns true if `response` should be returned as-is from the enclosing
    # transaction. Closes the body as a side effect when the response is
    # cascading so callers can safely try the next match.
    def halt?(response)
      return false unless response

      cascade = cascade?(response)
      response[2].close if cascade && response[2].respond_to?(:close)
      !cascade
    end

    def process_route(route, input, env, include_allow_header: false)
      args = env[Grape::Env::GRAPE_ROUTING_ARGS] || { route_info: route }
      route_params = route.params(input)
      env[Grape::Env::GRAPE_ROUTING_ARGS] = route_params.blank? ? args : args.merge(route_params)
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
      @optimized_map[method].match(input) { |m| @map[method].detect { |route| m[route.regexp_capture_index] } }
    end

    def greedy_match?(input)
      @union.match(input) { |m| @neutral_map.detect { |route| m[route.regexp_capture_index] } }
    end

    def cascade?(response)
      response && response[1]['X-Cascade'] == 'pass'
    end
  end
end
