module Grape
  class Cookies

      def initialize
        @cookies = {}
        @send_cookies = {}
      end

      def read(request)
        request.cookies.each do |name, value|
          @cookies[name.to_sym] = value
        end
      end

      def write(header)
        @cookies.select { |key, value|
            @send_cookies[key.to_sym] == true
        }.each { |name, value|
          Rack::Utils.set_cookie_header!(
            header, name, value.instance_of?(Hash) ? value : { :value => value })
        }
      end

      def [](name)
        @cookies[name]
      end

      def []=(name, value)
        @cookies[name.to_sym] = value
        @send_cookies[name.to_sym] = true
      end

      def each(&block)
        @cookies.each(&block)
      end

      def delete(name)
        self.[]=(name, { :value => 'deleted', :expires => Time.at(0) })
      end
    end
end