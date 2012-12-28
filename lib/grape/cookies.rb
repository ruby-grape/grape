require 'active_support/core_ext/hash/indifferent_access'

module Grape
  class Cookies

    def initialize
      @cookies = HashWithIndifferentAccess.new
      @send_cookies = HashWithIndifferentAccess.new
    end

    def read(request)
      request.cookies.each do |name, value|
        @cookies[name.to_s] = value
      end
    end

    def write(header)
      @cookies.select { |key, value|
        @send_cookies[key] == true
      }.each { |name, value|
        cookie_value = value.is_a?(Hash) ? value : { :value => value }
        Rack::Utils.set_cookie_header! header, name, cookie_value
      }
    end

    def [](name)
      @cookies[name]
    end

    def []=(name, value)
      @cookies[name] = value
      @send_cookies[name] = true
    end

    def each(&block)
      @cookies.each(&block)
    end

    def delete(name)
      self.[]=(name, { :value => 'deleted', :expires => Time.at(0) })
    end

  end
end