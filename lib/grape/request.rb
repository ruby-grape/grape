module Grape
  class Request < Rack::Request
    HTTP_PREFIX = 'HTTP_'.freeze

    def params
      @params ||= begin
        params = Hashie::Mash.new(super)
        if env[Grape::Env::RACK_ROUTING_ARGS]
          args = env[Grape::Env::RACK_ROUTING_ARGS].dup
          # preserve version from query string parameters
          args.delete(:version)
          args.delete(:route_info)
          params.deep_merge!(args)
        end
        params
      end
    end

    def headers
      @headers ||= env.each_with_object({}) do |(k, v), h|
        next unless k.to_s.start_with? HTTP_PREFIX

        k = k[5..-1].split('_').each(&:capitalize!).join('-')
        h[k] = v
      end
    end
  end
end
