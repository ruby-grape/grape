# frozen_string_literal: true

module Grape
  class Cookies
    extend Forwardable

    DELETED_COOKIES_ATTRS = {
      max_age: '0',
      value: '',
      expires: Time.at(0)
    }.freeze

    def_delegators :cookies, :[], :each

    def initialize(rack_cookies)
      @cookies = rack_cookies
      @send_cookies = nil
    end

    def response_cookies
      return unless @send_cookies

      send_cookies.each do |name|
        yield name, cookies[name]
      end
    end

    def []=(name, value)
      cookies[name] = value
      send_cookies << name
    end

    # see https://github.com/rack/rack/blob/main/lib/rack/utils.rb#L338-L340
    def delete(name, **opts)
      self.[]=(name, opts.merge(DELETED_COOKIES_ATTRS))
    end

    private

    def cookies
      return @cookies unless @cookies.is_a?(Proc)

      @cookies = @cookies.call.with_indifferent_access
    end

    def send_cookies
      @send_cookies ||= Set.new
    end
  end
end
