# frozen_string_literal: true

module Grape
  class Request < Rack::Request
    HTTP_PREFIX = 'HTTP_'

    alias rack_params params

    def initialize(env, build_params_with: nil)
      extend build_params_with || Grape.config.param_builder
      super(env)
    end

    def params
      @params ||= build_params
    rescue EOFError
      raise Grape::Exceptions::EmptyMessageBody.new(content_type)
    rescue Rack::Multipart::MultipartPartLimitError
      raise Grape::Exceptions::TooManyMultipartFiles.new(Rack::Utils.multipart_part_limit)
    end

    def headers
      @headers ||= build_headers
    end

    private

    def grape_routing_args
      # preserve version from query string parameters
      env[Grape::Env::GRAPE_ROUTING_ARGS].except(:version, :route_info)
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
