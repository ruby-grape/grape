# frozen_string_literal: true

module Grape
  class Request < Rack::Request
    DEFAULT_PARAMS_BUILDER = :hash_with_indifferent_access
    HTTP_PREFIX = 'HTTP_'
    KNOWN_HEADERS = %w[
      Accept-CH
      Accept-Patch
      Accept-Ranges
      Access-Control-Allow-Credentials
      Access-Control-Allow-Headers
      Access-Control-Allow-Methods
      Access-Control-Allow-Origin
      Access-Control-Expose-Headers
      Access-Control-Max-Age
      Age
      Allow
      Alt-Svc
      Cache-Control
      Connection
      Content-Disposition
      Content-Encoding
      Content-Language
      Content-Length
      Content-Location
      Content-MD5
      Content-Range
      Content-Security-Policy
      Content-Security-Policy-Report-Only
      Content-Type
      Date
      Delta-Base
      ETag
      Expect-CT
      Expires
      Feature-Policy
      IM
      Last-Modified
      Link
      Location
      NEL
      P3P
      Permissions-Policy
      Pragma
      Preference-Applied
      Proxy-Authenticate
      Public-Key-Pins
      Referrer-Policy
      Refresh
      Report-To
      Retry-After
      Server
      Set-Cookie
      Status
      Strict-Transport-Security
      Timing-Allow-Origin
      Tk
      Trailer
      Transfer-Encoding
      Upgrade
      Vary
      Via
      WWW-Authenticate
      Warning
      X-Cascade
      X-Content-Duration
      X-Content-Security-Policy
      X-Content-Type-Options
      X-Correlation-ID
      X-Correlation-Id
      X-Download-Options
      X-Frame-Options
      X-Permitted-Cross-Domain-Policies
      X-Powered-By
      X-Redirect-By
      X-Request-ID
      X-Request-Id
      X-Runtime
      X-UA-Compatible
      X-WebKit-CS
      X-XSS-Protection
      Version
    ].each_with_object({}) do |header, response|
      response["#{HTTP_PREFIX}#{header.upcase.tr('-', '_')}"] = header
    end.freeze

    alias rack_params params
    alias rack_cookies cookies

    def initialize(env, build_params_with: nil)
      super(env)
      @params_builder = Grape::ParamsBuilder.params_builder_for(build_params_with || Grape.config.param_builder)
    end

    def params
      @params ||= make_params
    end

    def headers
      @headers ||= build_headers
    end

    def cookies
      @cookies ||= Grape::Cookies.new(-> { rack_cookies })
    end

    # needs to be public until extensions param_builder are removed
    def grape_routing_args
      # preserve version from query string parameters
      env[Grape::Env::GRAPE_ROUTING_ARGS]&.except(:version, :route_info) || {}
    end

    private

    def make_params
      @params_builder.call(rack_params).deep_merge!(grape_routing_args)
    rescue EOFError
      raise Grape::Exceptions::EmptyMessageBody.new(content_type)
    rescue Rack::Multipart::MultipartPartLimitError
      raise Grape::Exceptions::TooManyMultipartFiles.new(Rack::Utils.multipart_part_limit)
    end

    def build_headers
      each_header.with_object(Grape::Util::Header.new) do |(k, v), headers|
        next unless k.start_with? HTTP_PREFIX

        transformed_header = KNOWN_HEADERS.fetch(k) { -k[5..].tr('_', '-').downcase }
        headers[transformed_header] = v
      end
    end
  end
end
