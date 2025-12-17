# frozen_string_literal: true

module Grape
  class Router
    # Taken from Rails
    #     normalize_path("/foo")  # => "/foo"
    #     normalize_path("/foo/") # => "/foo"
    #     normalize_path("foo")   # => "/foo"
    #     normalize_path("")      # => "/"
    #     normalize_path("/%ab")  # => "/%AB"
    # https://github.com/rails/rails/blob/00cc4ff0259c0185fe08baadaa40e63ea2534f6e/actionpack/lib/action_dispatch/journey/router/utils.rb#L19
    def self.normalize_path(path)
      return '/' unless path
      return path if path == '/'

      # Fast path for the overwhelming majority of paths that don't need to be normalized
      return path if path.start_with?('/') && !(path.end_with?('/') || path.match?(%r{%|//}))

      # Slow path
      encoding = path.encoding
      path = "/#{path}"
      path.squeeze!('/')

      unless path == '/'
        path.delete_suffix!('/')
        path.gsub!(/(%[a-f0-9]{2})/) { ::Regexp.last_match(1).upcase }
      end

      path.force_encoding(encoding)
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
        input = Router.normalize_path(env[Rack::PATH_INFO])
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
      # using a Proc is important since `return` will exit the enclosing function
      cascade_or_return_response = proc do |response|
        if response
          cascade?(response).tap do |cascade|
            return response unless cascade

            # we need to close the body if possible before dismissing
            response[2].close if response[2].respond_to?(:close)
          end
        end
      end

      response = yield
      last_response_cascade = cascade_or_return_response.call(response)
      last_neighbor_route = greedy_match?(input)

      # If last_neighbor_route exists and request method is OPTIONS,
      # return response by using #include_allow_header.
      return process_route(last_neighbor_route, input, env, include_allow_header: true) if !last_response_cascade && method == Rack::OPTIONS && last_neighbor_route

      route = match?(input, '*')

      return last_neighbor_route.call(env) if last_neighbor_route && last_response_cascade && route

      last_response_cascade = cascade_or_return_response.call(process_route(route, input, env)) if route

      return process_route(last_neighbor_route, input, env, include_allow_header: true) if !last_response_cascade && last_neighbor_route

      nil
    end

    def process_route(route, input, env, include_allow_header: false)
      args = env[Grape::Env::GRAPE_ROUTING_ARGS] || { route_info: route }
      route_params = route.params(input)
      routing_args = args.merge(route_params || {})
      env[Grape::Env::GRAPE_ROUTING_ARGS] = routing_args
      env[Grape::Env::GRAPE_ALLOWED_METHODS] = route.allow_header if include_allow_header
      route.call(env)
    end

    def with_optimization
      compile!
      yield || default_response
    end

    def default_response
      headers = Grape::Util::Header.new.merge('X-Cascade' => 'pass')
      [404, headers, ['404 Not Found']]
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
