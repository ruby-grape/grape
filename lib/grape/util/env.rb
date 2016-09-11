module Grape
  module Env
    API_VERSION = 'api.version'.freeze
    API_ENDPOINT = 'api.endpoint'.freeze
    API_REQUEST_INPUT = 'api.request.input'.freeze
    API_REQUEST_BODY = 'api.request.body'.freeze
    API_TYPE = 'api.type'.freeze
    API_SUBTYPE = 'api.subtype'.freeze
    API_VENDOR = 'api.vendor'.freeze
    API_FORMAT = 'api.format'.freeze

    RACK_INPUT = 'rack.input'.freeze
    RACK_REQUEST_QUERY_HASH = 'rack.request.query_hash'.freeze
    RACK_REQUEST_FORM_HASH = 'rack.request.form_hash'.freeze
    RACK_REQUEST_FORM_INPUT = 'rack.request.form_input'.freeze

    GRAPE_REQUEST = 'grape.request'.freeze
    GRAPE_REQUEST_HEADERS = 'grape.request.headers'.freeze
    GRAPE_REQUEST_PARAMS = 'grape.request.params'.freeze
    GRAPE_ROUTING_ARGS = 'grape.routing_args'.freeze
    GRAPE_ALLOWED_METHODS = 'grape.allowed_methods'.freeze
  end
end
