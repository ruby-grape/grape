# frozen_string_literal: true

module Grape
  class Request < Rack::Request
    # Rack::Headers::KNOWN_HEADERS covers response headers only. Without the
    # request headers every client sends, #build_headers would build each of
    # their names from the env key, and Rack::Headers#[]= would downcase it again.
    REQUEST_HEADERS = %w[
      accept
      accept-encoding
      accept-language
      accept-version
      authorization
      client-ip
      cookie
      dnt
      forwarded
      host
      if-modified-since
      if-none-match
      range
      referer
      sec-fetch-dest
      sec-fetch-mode
      sec-fetch-site
      sec-fetch-user
      upgrade-insecure-requests
      user-agent
      version
      x-accel-buffering
      x-accel-charset
      x-accel-expires
      x-accel-limit-rate
      x-accel-mapping
      x-accel-redirect
      x-access-token
      x-auth-request-access-token
      x-auth-request-email
      x-auth-request-groups
      x-auth-request-preferred-username
      x-auth-request-redirect
      x-auth-request-token
      x-auth-request-user
      x-client-ip
      x-forwarded-access-token
      x-forwarded-email
      x-forwarded-for
      x-forwarded-groups
      x-forwarded-host
      x-forwarded-port
      x-forwarded-preferred-username
      x-forwarded-proto
      x-forwarded-scheme
      x-forwarded-ssl
      x-forwarded-uri
      x-forwarded-user
      x-http-method-override
      x-real-ip
      x-requested-with
      x-sendfile
      x-sendfile-type
    ].freeze
    private_constant :REQUEST_HEADERS

    # Env key => header name. Rack's names are the frozen Strings
    # Rack::Headers#[]= looks up, so a known header is stored without copying.
    KNOWN_HEADERS = (Rack::Headers::KNOWN_HEADERS.values.uniq + REQUEST_HEADERS).to_h do |header|
      ["HTTP_#{header.upcase.tr('-', '_')}", header]
    end.freeze

    # Routing-args keys that are Grape's own, not request params.
    GRAPE_OWNED_ROUTING_ARGS = %i[version route_info].freeze
    ROUTE_INFO_ONLY = %i[route_info].freeze

    alias rack_params params
    alias rack_cookies cookies

    def initialize(env, build_params_with: nil)
      super(env)
      @build_params_with = build_params_with
    end

    def params
      @params ||= make_params
    end

    def headers
      @headers ||= build_headers
    end

    def cookies
      @cookies ||= Grape::Cookies.new(rack_cookies)
    end

    # True once the cookie jar has been materialized (a cookie was read or
    # written this request). Lets the endpoint skip response-cookie flushing,
    # and the Grape::Cookies allocation it triggers, when no cookie was
    # touched on the request.
    def cookies?
      !@cookies.nil?
    end

    private

    # Resolved on first use rather than in the constructor: a request that never
    # reads +params+ -- an endpoint with no validations whose block does not ask
    # for them -- pays neither the registry lookup nor the global config read,
    # and every request builds a Grape::Request.
    def params_builder
      @params_builder ||= Grape::ParamsBuilder.params_builder_for(@build_params_with || Grape.config[:param_builder])
    end

    # Whether the request can have form params at all. Rack::Request#params is
    # the query params merged with the form params, and a request that carries
    # no body has none to merge -- but finding that out costs Rack a
    # CONTENT_TYPE parse and an empty Hash written back into the env, on every
    # request that reads params without sending a body. The env answers it
    # first: form params already read, by Rack or by the formatter's parsers,
    # are memoized under Rack's own key, and without them only a body could
    # hold any. The method is deliberately not part of the test -- Rack reads
    # a form body whatever the method says.
    def form_params?
      return true if env.key?(Rack::RACK_REQUEST_FORM_HASH)

      env['CONTENT_LENGTH'].to_i.positive? || env['HTTP_TRANSFER_ENCODING'] == 'chunked'
    end

    # +self.GET+ is the query hash Rack memoized in the env, not the copy the
    # merge in Rack::Request#params used to hand over. Every builder Grape
    # ships constructs a new object, so there is nothing to copy; one that
    # returns its argument would otherwise let the writes that follow --
    # routing args, coercions, defaults -- reach the env.
    def build_params
      return params_builder.call(rack_params) if form_params?

      query_hash = self.GET
      built = params_builder.call(query_hash)
      built.equal?(query_hash) ? built.dup : built
    end

    def make_params
      params = build_params
      merge_routing_args!(params, env[Grape::Env::GRAPE_ROUTING_ARGS])
      params
    rescue *Grape::RACK_ERRORS
      raise Grape::Exceptions::RequestError
    end

    # The routing args carry two things that are not request params:
    # +:route_info+, which is always Grape's own, and +:version+, which is only
    # Grape's own when the API declared a version — that is captured as a path
    # segment and exposed through +env['api.version']+ instead.
    #
    # An API that declares no version can legitimately name a param +:version+
    # (`route_param :version`, `get '/:version'`), and that capture belongs to
    # the application. Dropping it unconditionally left `params[:version]` nil
    # on a route that had matched, losing the segment silently.
    #
    # The rest are written into +params+ one by one rather than deep-merged
    # from an +except+ copy, which was a Hash built per request only to be
    # merged away. A capture is a String or an Array of them, never a Hash,
    # so +deep_merge!+ had nothing to merge into: it replaced the value, as
    # assigning it does.
    def merge_routing_args!(params, routing_args)
      return if routing_args.nil?

      grape_owned = grape_owns_version?(routing_args) ? GRAPE_OWNED_ROUTING_ARGS : ROUTE_INFO_ONLY
      routing_args.each do |key, value|
        params[key] = value unless grape_owned.include?(key)
      end
    end

    # A route reports a +version+ only when the API declared one, which is the
    # case where the captured segment is Grape's rather than the application's.
    def grape_owns_version?(routing_args)
      return false unless routing_args.key?(:version)

      route = routing_args[:route_info]
      route.respond_to?(:version) && !route.version.nil?
    end

    # Uses a plain `each_header` block instead of `each_header.with_object`:
    # `with_object` can only pass the block one value plus the memo, so the
    # `k, v` pair would be boxed into a throwaway Array on every header. A
    # two-arg block receives `k`/`v` directly and allocates nothing extra.
    def build_headers
      headers = Rack::Headers.new
      each_header do |k, v|
        next unless k.start_with? 'HTTP_'

        transformed_header = KNOWN_HEADERS.fetch(k) { -k[5..].tr('_', '-').downcase }
        headers[transformed_header] = v
      end
      headers
    end
  end
end
