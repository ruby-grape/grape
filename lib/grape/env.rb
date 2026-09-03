# frozen_string_literal: true

module Grape
  module Env
    API_VERSION = 'api.version'
    API_ENDPOINT = 'api.endpoint'
    API_REQUEST_INPUT = 'api.request.input'
    API_REQUEST_BODY = 'api.request.body'
    API_TYPE = 'api.type'
    API_SUBTYPE = 'api.subtype'
    API_VENDOR = 'api.vendor'
    API_FORMAT = 'api.format'

    GRAPE_NORMALIZED_PATH = 'grape.normalized_path'
    GRAPE_ROUTING_ARGS = 'grape.routing_args'
    GRAPE_ALLOWED_METHODS = 'grape.allowed_methods'
    GRAPE_EXCEPTION = 'grape.exception'

    # Not a Grape-owned key: the de-facto convention for an exception that was
    # handled rather than raised, which is how error trackers find one they
    # never saw propagate. sentry-ruby, for one, collects
    # +env['rack.exception'] || env['sinatra.error']+.
    RACK_EXCEPTION = 'rack.exception'
  end
end
