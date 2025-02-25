# frozen_string_literal: true

module Grape
  class Request < Rack::Request
    DEFAULT_PARAMS_BUILDER = :hash_with_indifferent_access
    HTTP_PREFIX = 'HTTP_'

    alias rack_params params

    def initialize(env, build_params_with: nil)
      super(env)
      @params_builder = Grape::ParamsBuilder.params_builder_for(build_params_with || DEFAULT_PARAMS_BUILDER)
    end

    def params
      @params ||= make_params
    end

    def headers
      @headers ||= build_headers
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
    rescue Rack::QueryParser::ParameterTypeError, Rack::QueryParser::InvalidParameterError, Rack::QueryParser::ParamsTooDeepError
      raise Grape::Exceptions::QueryParsing
    end

    def build_headers
      each_header.with_object(Grape::Util::Header.new) do |(k, v), headers|
        next unless k.start_with? HTTP_PREFIX

        transformed_header = Grape::Http::Headers::HTTP_HEADERS[k] || transform_header(k)
        headers[transformed_header] = v
      end
    end

    def transform_header(header)
      -header[5..].tr('_', '-').downcase
    end
  end
end
