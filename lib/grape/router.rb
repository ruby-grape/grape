require 'grape/router/route'

module Grape
  class Router
    attr_reader :map, :compiled

    class Any < AttributeTranslator
      def initialize(pattern, attributes = {})
        @pattern = pattern
        super(attributes)
      end
    end

    def initialize
      @neutral_map = []
      @map = Hash.new { |hash, key| hash[key] = [] }
      @optimized_map = Hash.new { |hash, key| hash[key] = // }
    end

    def compile!
      return if compiled
      @union = Regexp.union(@neutral_map.map(&:regexp))
      map.each do |method, routes|
        @optimized_map[method] = routes.map.with_index do |route, index|
          route.index = index
          route.regexp = /(?<_#{index}>#{route.pattern.to_regexp})/
        end
        @optimized_map[method] = Regexp.union(@optimized_map[method])
      end
      @compiled = true
    end

    def append(route)
      map[route.request_method.to_s.upcase] << route
    end

    def associate_routes(pattern, options = {})
      regexp = /(?<_#{@neutral_map.length}>)#{pattern.to_regexp}/
      @neutral_map << Any.new(pattern, options.merge(regexp: regexp, index: @neutral_map.length))
    end

    def call(env)
      with_optimization do
        identity(env) || rotation(env) { |route| route.exec(env) }
      end
    end

    def recognize_path(input)
      any = with_optimization { greedy_match?(input) }
      return if any == default_response
      any.endpoint
    end

    private

    def identity(env)
      transaction(env) do |input, method, routing_args|
        route = match?(input, method)
        if route
          env[Grape::Env::GRAPE_ROUTING_ARGS] = make_routing_args(routing_args, route, input)
          route.exec(env)
        end
      end
    end

    def rotation(env)
      transaction(env) do |input, method, routing_args|
        response = nil
        routes_for(method).each do |route|
          next unless route.match?(input)
          env[Grape::Env::GRAPE_ROUTING_ARGS] = make_routing_args(routing_args, route, input)
          response = yield(route)
          break unless cascade?(response)
        end
        response
      end
    end

    def transaction(env)
      input, method, routing_args = *extract_required_args(env)
      response = yield(input, method, routing_args)

      return response if response && !(cascade = cascade?(response))
      neighbor = greedy_match?(input)
      return unless neighbor

      (!cascade && neighbor) ? method_not_allowed(env, neighbor.allow_header, neighbor.endpoint) : nil
    end

    def make_routing_args(default_args, route, input)
      args = default_args || { route_info: route }
      args.merge(route.params(input))
    end

    def extract_required_args(env)
      input = string_for(env[Grape::Http::Headers::PATH_INFO])
      method = env[Grape::Http::Headers::REQUEST_METHOD]
      routing_args = env[Grape::Env::GRAPE_ROUTING_ARGS]
      [input, method, routing_args]
    end

    def with_optimization
      compile! unless compiled
      yield || default_response
    end

    def default_response
      [404, { Grape::Http::Headers::X_CASCADE => 'pass' }, ['404 Not Found']]
    end

    def match?(input, method)
      current_regexp = @optimized_map[method]
      return unless current_regexp.match(input)
      last_match = Regexp.last_match
      @map[method].detect { |route| last_match["_#{route.index}"] }
    end

    def greedy_match?(input)
      return unless @union.match(input)
      last_match = Regexp.last_match
      @neutral_map.detect { |route| last_match["_#{route.index}"] }
    end

    def method_not_allowed(env, methods, endpoint)
      current = endpoint.dup
      current.instance_eval do
        run_filters befores, :before
        @method_not_allowed = true
        @block = proc do
          fail Grape::Exceptions::MethodNotAllowed, header.merge('Allow' => methods)
        end
      end
      current.call(env)
    end

    def cascade?(response)
      response && response[1][Grape::Http::Headers::X_CASCADE] == 'pass'
    end

    def routes_for(method)
      map[method] + map['ANY']
    end

    def string_for(input)
      self.class.normalize_path(input)
    end

    def self.normalize_path(path)
      path = "/#{path}"
      path.squeeze!('/')
      path.sub!(%r{/+\Z}, '')
      path = '/' if path == ''
      path
    end
  end
end
