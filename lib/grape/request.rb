# frozen_string_literal: true

module Grape
  class Request < Rack::Request
    # Based on rack 3 KNOWN_HEADERS
    # https://github.com/rack/rack/blob/4f15e7b814922af79605be4b02c5b7c3044ba206/lib/rack/headers.rb#L10

    KNOWN_HEADERS = %w[
      Accept
      Accept-CH
      Accept-Encoding
      Accept-Language
      Accept-Patch
      Accept-Ranges
      Accept-Version
      Access-Control-Allow-Credentials
      Access-Control-Allow-Headers
      Access-Control-Allow-Methods
      Access-Control-Allow-Origin
      Access-Control-Expose-Headers
      Access-Control-Max-Age
      Age
      Allow
      Alt-Svc
      Authorization
      Cache-Control
      Client-Ip
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
      Cookie
      Date
      Delta-Base
      Dnt
      ETag
      Expect-CT
      Expires
      Feature-Policy
      Forwarded
      Host
      If-Modified-Since
      If-None-Match
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
      Range
      Referer
      Referrer-Policy
      Refresh
      Report-To
      Retry-After
      Sec-Fetch-Dest
      Sec-Fetch-Mode
      Sec-Fetch-Site
      Sec-Fetch-User
      Server
      Set-Cookie
      Status
      Strict-Transport-Security
      Timing-Allow-Origin
      Tk
      Trailer
      Transfer-Encoding
      Upgrade
      Upgrade-Insecure-Requests
      User-Agent
      Vary
      Version
      Via
      Warning
      WWW-Authenticate
      X-Accel-Buffering
      X-Accel-Charset
      X-Accel-Expires
      X-Accel-Limit-Rate
      X-Accel-Mapping
      X-Accel-Redirect
      X-Access-Token
      X-Auth-Request-Access-Token
      X-Auth-Request-Email
      X-Auth-Request-Groups
      X-Auth-Request-Preferred-Username
      X-Auth-Request-Redirect
      X-Auth-Request-Token
      X-Auth-Request-User
      X-Cascade
      X-Client-Ip
      X-Content-Duration
      X-Content-Security-Policy
      X-Content-Type-Options
      X-Correlation-Id
      X-Download-Options
      X-Forwarded-Access-Token
      X-Forwarded-Email
      X-Forwarded-For
      X-Forwarded-Groups
      X-Forwarded-Host
      X-Forwarded-Port
      X-Forwarded-Preferred-Username
      X-Forwarded-Proto
      X-Forwarded-Scheme
      X-Forwarded-Ssl
      X-Forwarded-Uri
      X-Forwarded-User
      X-Frame-Options
      X-HTTP-Method-Override
      X-Permitted-Cross-Domain-Policies
      X-Powered-By
      X-Real-IP
      X-Redirect-By
      X-Request-Id
      X-Requested-With
      X-Runtime
      X-Sendfile
      X-Sendfile-Type
      X-UA-Compatible
      X-WebKit-CS
      X-XSS-Protection
    ].each_with_object({}) do |header, response|
      response["HTTP_#{header.upcase.tr('-', '_')}"] = header
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
    rescue Rack::Multipart::MultipartPartLimitError, Rack::Multipart::MultipartTotalPartLimitError
      raise Grape::Exceptions::TooManyMultipartFiles.new(Rack::Utils.multipart_part_limit)
    rescue Rack::QueryParser::ParamsTooDeepError
      raise Grape::Exceptions::TooDeepParameters.new(Rack::Utils.param_depth_limit)
    rescue Rack::Utils::ParameterTypeError
      raise Grape::Exceptions::ConflictingTypes
    rescue Rack::Utils::InvalidParameterError
      raise Grape::Exceptions::InvalidParameters
    end

    def build_headers
      each_header.with_object(Grape::Util::Header.new) do |(k, v), headers|
        next unless k.start_with? 'HTTP_'

        transformed_header = KNOWN_HEADERS.fetch(k) { -k[5..].tr('_', '-').downcase }
        headers[transformed_header] = v
      end
    end
  end
end
