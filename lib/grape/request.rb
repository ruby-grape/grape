module Grape
  class Request < Rack::Request
    HTTP_PREFIX = 'HTTP_'.freeze

    alias rack_params params

    def params
      @params ||= build_params
    end

    def headers
      @headers ||= build_headers
    end

    private

    def build_params
      params = Hashie::Mash.new(rack_params)
      if env[Grape::Env::GRAPE_ROUTING_ARGS]
        args = env[Grape::Env::GRAPE_ROUTING_ARGS].dup
        # preserve version from query string parameters
        args.delete(:version)
        args.delete(:route_info)
        params.deep_merge!(args)
      end
      params
    end

    def build_headers
      headers = {}
      env.each_pair do |k, v|
        next unless k.to_s.start_with? HTTP_PREFIX

        k = k[5..-1].split('_').each(&:capitalize!).join('-')
        headers[k] = v
      end
      headers
    end
  end
end
