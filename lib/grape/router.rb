# frozen_string_literal: true

module Grape
  class Router
    attr_reader :map, :compiled

    # Taken from Rails
    #     normalize_path("/foo")  # => "/foo"
    #     normalize_path("/foo/") # => "/foo"
    #     normalize_path("foo")   # => "/foo"
    #     normalize_path("")      # => "/"
    #     normalize_path("/%ab")  # => "/%AB"
    # https://github.com/rails/rails/blob/00cc4ff0259c0185fe08baadaa40e63ea2534f6e/actionpack/lib/action_dispatch/journey/router/utils.rb#L19
    def self.normalize_path(path)
      return +'/' unless path

      # Fast path for the overwhelming majority of paths that don't need to be normalized
      return path.dup if path == '/' || (path.start_with?('/') && !(path.end_with?('/') || path.match?(%r{%|//})))

      # Slow path
      encoding = path.encoding
      path = +"/#{path}"
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
      return if compiled

      @union = Regexp.union(@neutral_regexes)
      @neutral_regexes = nil
      (Grape::HTTP_SUPPORTED_METHODS + ['*']).each do |method|
        next unless map.key?(method)

        routes = map[method]
        optimized_map = routes.map.with_index { |route, index| route.to_regexp(index) }
        @optimized_map[method] = Regexp.union(optimized_map)
      end
      @compiled = true
    end

    def append(route)
      map[route.request_method] << route
    end

    def associate_routes(pattern, options)
      Grape::Router::GreedyRoute.new(pattern, options).then do |greedy_route|
        @neutral_regexes << greedy_route.to_regexp(@neutral_map.length)
        @neutral_map << greedy_route
      end
    end

    def call(env)
      with_optimization do
        response, route = identity(env)
        response || rotation(env, route)
      end
    end

    def recognize_path(input)
      any = with_optimization { greedy_match?(input) }
      return if any == default_response

      any.endpoint
    end

    private

    def identity(env)
      route = nil
      response = transaction(env) do |input, method|
        route = match?(input, method)
        process_route(route, env) if route
      end
      [response, route]
    end

    def rotation(env, exact_route = nil)
      response = nil
      input, method = *extract_input_and_method(env)
      map[method].each do |route|
        next if exact_route == route
        next unless route.match?(input)

        response = process_route(route, env)
        break unless cascade?(response)
      end
      response
    end

    def transaction(env)
      input, method = *extract_input_and_method(env)

      # using a Proc is important since `return` will exit the enclosing function
      cascade_or_return_response = proc do |response|
        if response
          cascade?(response).tap do |cascade|
            return response unless cascade

            # we need to close the body if possible before dismissing
            response[2].try(:close)
          end
        end
      end

      last_response_cascade = cascade_or_return_response.call(yield(input, method))
      last_neighbor_route = greedy_match?(input)

      # If last_neighbor_route exists and request method is OPTIONS,
      # return response by using #call_with_allow_headers.
      return call_with_allow_headers(env, last_neighbor_route) if last_neighbor_route && method == Rack::OPTIONS && !last_response_cascade

      route = match?(input, '*')

      return last_neighbor_route.options[:endpoint].call(env) if last_neighbor_route && last_response_cascade && route

      last_response_cascade = cascade_or_return_response.call(process_route(route, env)) if route

      return call_with_allow_headers(env, last_neighbor_route) if !last_response_cascade && last_neighbor_route

      nil
    end

    def process_route(route, env)
      prepare_env_from_route(env, route)
      route.exec(env)
    end

    def make_routing_args(default_args, route, input)
      args = default_args || { route_info: route }
      args.merge(route.params(input))
    end

    def extract_input_and_method(env)
      input = string_for(env[Rack::PATH_INFO])
      method = env[Rack::REQUEST_METHOD]
      [input, method]
    end

    def with_optimization
      compile! unless compiled
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

    def call_with_allow_headers(env, route)
      prepare_env_from_route(env, route)
      env[Grape::Env::GRAPE_ALLOWED_METHODS] = route.options[:allow_header]
      route.options[:endpoint].call(env)
    end

    def prepare_env_from_route(env, route)
      input, = *extract_input_and_method(env)
      env[Grape::Env::GRAPE_ROUTING_ARGS] = make_routing_args(env[Grape::Env::GRAPE_ROUTING_ARGS], route, input)
    end

    def cascade?(response)
      response && response[1]['X-Cascade'] == 'pass'
    end

    def string_for(input)
      self.class.normalize_path(input)
    end
  end
end
