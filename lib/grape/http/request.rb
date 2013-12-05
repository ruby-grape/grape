module Grape
  class Request < Rack::Request
    def params
      @params ||= begin
        params = Hashie::Mash.new(super)
        if env['rack.routing_args']
          args = env['rack.routing_args'].dup
          # preserve version from query string parameters
          args.delete(:version)
          params.deep_merge!(args)
        end
        params
      end
    end

    def headers
      @headers ||= env.dup.inject({}) do |h, (k, v)|
        if k.to_s.start_with? 'HTTP_'
          k = k[5..-1].gsub('_', '-').downcase.gsub(/^.|[-_\s]./) { |x| x.upcase }
          h[k] = v
        end
        h
      end
    end
  end
end
