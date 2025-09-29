# frozen_string_literal: true

module Grape
  module DSL
    # Module for extracting body metadata for endpoint notifications
    # This provides information about the response body without reading its content
    module BodyMetadata
      # Extract body metadata for endpoint notifications
      # This provides information about the response body without reading its content
      def extract_endpoint_body_metadata
        metadata = {
          has_body: instance_variable_defined?(:@body) && !@body.nil?,
          has_stream: instance_variable_defined?(:@stream) && !@stream.nil?,
          status: instance_variable_defined?(:@status) ? @status : nil
        }

        if metadata[:has_body]
          metadata[:body_type] = @body.class.name
          metadata[:body_responds_to_size] = @body.respond_to?(:size)
          metadata[:body_size] = @body.respond_to?(:size) ? @body.size : nil
        end

        if metadata[:has_stream]
          metadata[:stream_type] = @stream.class.name
          if @stream.respond_to?(:stream)
            metadata[:stream_inner_type] = @stream.stream.class.name
            metadata[:stream_file_path] = @stream.stream.to_path if @stream.stream.respond_to?(:to_path)
          end
        end

        if env
          metadata[:api_format] = env[Grape::Env::API_FORMAT]
          metadata[:content_type] = env['CONTENT_TYPE']
        end

        metadata
      end
    end
  end
end
