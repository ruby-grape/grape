module Grape
  class Request < Rack::Request
    ROUTING_ARGS = 'rack.routing_args'
    HTTP_PREFIX  = 'HTTP_'
    UNDERSCORE   = '_'
    MINUS        = '-'

    def params
      @params ||= begin
        params = Hashie::Mash.new(super)
        if env[ROUTING_ARGS]
          args = env[ROUTING_ARGS].dup
          # preserve version from query string parameters
          args.delete(:version)
          args.delete(:route_info)
          params.deep_merge!(args)
        end
        params
      end
    end

    def headers
      @headers ||= env.dup.inject({}) do |h, (k, v)|
        if k.to_s.start_with? HTTP_PREFIX
          k = k[5..-1]
          k.tr!(UNDERSCORE, MINUS)
          k.downcase!
          k.gsub!(/^.|[-_\s]./, &:upcase!)
          h[k] = v
        end
        h
      end
    end
  end
end
