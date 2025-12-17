# frozen_string_literal: true

module Grape
  module Middleware
    class Formatter < Base
      DEFAULT_OPTIONS = {
        default_format: :txt
      }.freeze

      ALL_MEDIA_TYPES = '*/*'

      def before
        negotiate_content_type
        read_body_input
      end

      def after
        return unless @app_response

        status, headers, bodies = *@app_response

        if Rack::Utils::STATUS_WITH_NO_ENTITY_BODY.include?(status)
          [status, headers, []]
        else
          build_formatted_response(status, headers, bodies)
        end
      end

      private

      def build_formatted_response(status, headers, bodies)
        headers = ensure_content_type(headers)

        if bodies.is_a?(Grape::ServeStream::StreamResponse)
          Grape::ServeStream::SendfileResponse.new([], status, headers) do |resp|
            resp.body = bodies.stream
          end
        else
          # Allow content-type to be explicitly overwritten
          formatter = fetch_formatter(headers, options)
          bodymap = ActiveSupport::Notifications.instrument('format_response.grape', formatter: formatter, env: env) do
            bodies.collect { |body| formatter.call(body, env) }
          end
          Rack::Response.new(bodymap, status, headers)
        end
      rescue Grape::Exceptions::InvalidFormatter => e
        throw :error, status: 500, message: e.message, backtrace: e.backtrace, original_exception: e
      end

      def fetch_formatter(headers, options)
        api_format = env.fetch(Grape::Env::API_FORMAT) { mime_types[headers[Rack::CONTENT_TYPE]] }
        Grape::Formatter.formatter_for(api_format, options[:formatters])
      end

      # Set the content type header for the API format if it is not already present.
      #
      # @param headers [Hash]
      # @return [Hash]
      def ensure_content_type(headers)
        if headers[Rack::CONTENT_TYPE]
          headers
        else
          headers.merge(Rack::CONTENT_TYPE => content_type_for(env[Grape::Env::API_FORMAT]))
        end
      end

      def read_body_input
        input = rack_request.body # reads RACK_INPUT
        return if input.nil?
        return unless read_body_input?

        rewind = input.respond_to?(:rewind)

        input.rewind if rewind
        body = env[Grape::Env::API_REQUEST_INPUT] = input.read
        begin
          read_rack_input(body)
        ensure
          input.rewind if rewind
        end
      end

      def read_rack_input(body)
        return if body.empty?

        media_type = rack_request.media_type
        fmt = media_type ? mime_types[media_type] : options[:default_format]

        throw :error, status: 415, message: "The provided content-type '#{media_type}' is not supported." unless content_type_for(fmt)
        parser = Grape::Parser.parser_for fmt, options[:parsers]
        if parser
          begin
            body = (env[Grape::Env::API_REQUEST_BODY] = parser.call(body, env))
            if body.is_a?(Hash)
              env[Rack::RACK_REQUEST_FORM_HASH] = if env.key?(Rack::RACK_REQUEST_FORM_HASH)
                                                    env[Rack::RACK_REQUEST_FORM_HASH].merge(body)
                                                  else
                                                    body
                                                  end
              env[Rack::RACK_REQUEST_FORM_INPUT] = env[Rack::RACK_INPUT]
            end
          rescue Grape::Exceptions::Base => e
            raise e
          rescue StandardError => e
            throw :error, status: 400, message: e.message, backtrace: e.backtrace, original_exception: e
          end
        else
          env[Grape::Env::API_REQUEST_BODY] = body
        end
      end

      # this middleware will not try to format the following content-types since Rack already handles them
      # when calling Rack's `params` function
      # - application/x-www-form-urlencoded
      # - multipart/form-data
      # - multipart/related
      # - multipart/mixed
      def read_body_input?
        (rack_request.post? || rack_request.put? || rack_request.patch? || rack_request.delete?) &&
          !(rack_request.form_data? && rack_request.content_type) &&
          !rack_request.parseable_data? &&
          (rack_request.content_length.to_i.positive? || rack_request.env['HTTP_TRANSFER_ENCODING'] == 'chunked')
      end

      def negotiate_content_type
        fmt = format_from_extension || query_params['format'] || options[:format] || format_from_header || options[:default_format]
        if content_type_for(fmt)
          env[Grape::Env::API_FORMAT] = fmt.to_sym
        else
          throw :error, status: 406, message: "The requested format '#{fmt}' is not supported."
        end
      end

      def format_from_extension
        request_path = try_scrub(rack_request.path)
        dot_pos = request_path.rindex('.')
        return unless dot_pos

        extension = request_path[(dot_pos + 1)..]
        extension if content_type_for(extension)
      end

      def format_from_header
        accept_header = try_scrub(env['HTTP_ACCEPT'])
        return if accept_header.blank? || accept_header == ALL_MEDIA_TYPES

        media_type = Rack::Utils.best_q_match(accept_header, mime_types.keys)
        mime_types[media_type] if media_type
      end
    end
  end
end
