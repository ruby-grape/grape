module Grape
  class Cookies

      def initialize
        @send = true
        @cookies = {}
        @send_cookies = {}
      end

      def without_send
        @send = false
        yield self if block_given?
        @send = true
      end

      def [](name)
        @cookies[name]
      end

      def []=(name, value)
        @cookies[name.to_sym] = value
        @send_cookies[name.to_sym] = true if @send
      end

      def each(opt = nil, &block)
        if opt == :to_send
          @cookies.select { |key, value|
            @send_cookies[key.to_sym] == true
          }.each(&block)
        else
          @cookies.each(&block)
        end
      end

      def delete(name)
        self.[]=(name, { :value => 'deleted', :expires => Time.at(0) })
      end
    end
end