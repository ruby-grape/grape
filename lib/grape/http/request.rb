module Grape
  class Request < Rack::Request

    def params
      @env['grape.request.params'] ||= Hashie::Mash.new.
        deep_merge(super).
        deep_merge(env['rack.routing_args'] || {})
    end

    def headers
      @env['grape.request.headers'] ||= @env.dup.inject({}) { |h, (k, v)|
        if k.start_with? 'HTTP_'
          k = k[5..-1].gsub('_', '-').downcase.gsub(/^.|[-_\s]./) { |x| x.upcase }
          h[k] = v
        end
        h
      }
    end

  end
end
