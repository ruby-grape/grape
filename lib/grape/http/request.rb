module Grape
  class Request < Rack::Request
    class Params < ::Hash
      include Hashie::Extensions::MergeInitializer
      include Hashie::Extensions::IndifferentAccess
      include Hashie::Extensions::MethodAccess

      def convert_value(value)
        super(value).tap do |converted_value|
          if converted_value.is_a?(Hash)
            value_self = (class << converted_value; self; end)
            value_self.send :include, Hashie::Extensions::MethodAccess
          end
        end
      end
    end

    def params
      @params ||= begin
        params = Params.new(super)
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
