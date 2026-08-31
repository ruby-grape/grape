# frozen_string_literal: true

module Grape
  module Middleware
    class Formatter < Base
      extend Forwardable
      include PrecomputedContentTypes

      Options = Data.define(:content_types, :default_format, :format, :formatters, :parsers) do
        include Grape::Middleware::DeprecatedOptionsHashAccess

        def initialize(content_types: nil, default_format: :txt, format: nil, formatters: nil, parsers: nil)
          super
        end
      end

      # @deprecated Kept as a frozen Hash representation of the {Options}
      #   defaults for back-compat. Will be removed in a future release.
      DEFAULT_OPTIONS = Options.new.to_h.freeze

      ALL_MEDIA_TYPES = '*/*'

      def_delegators :config, :default_format, :format, :formatters, :parsers

      def before
        negotiate_content_type
        read_body_input
      end

      def after
        return unless @app_response

        status, headers, bodies = @app_response

        return [status, headers, []] if Rack::Utils::STATUS_WITH_NO_ENTITY_BODY.include?(status)

        build_formatted_response(status, headers, bodies)
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
          formatter = fetch_formatter(headers)
          bodymap = instrument_format_response(formatter) do
            bodies.map { |body| formatter.call(body, env) }
          end
          # A bare Rack tuple rather than a Rack::Response: +headers+ is already
          # a Grape::Util::Header (a Rack::Headers on Rack 3), so wrapping only
          # re-normalizes the same keys into a second Headers hash that
          # +Middleware::Base#call+ unwraps again with +to_a+ on the way out.
          # The 204/304 bodies Rack::Response#finish would blank are returned
          # above, before this point.
          [status, headers, bodymap]
        end
      rescue Grape::Exceptions::InvalidFormatter => e
        throw :error, Grape::Exceptions::ErrorResponse.new(status: 500, message: e.message, backtrace: e.backtrace, original_exception: e)
      end

      # Guards on +listening?+ so that with no subscriber the payload Hash and
      # notification machinery are skipped and the block runs directly (no added
      # allocations); the block is forwarded anonymously.
      def instrument_format_response(formatter, &)
        return yield unless ActiveSupport::Notifications.notifier.listening?('format_response.grape')

        ActiveSupport::Notifications.instrument('format_response.grape', formatter:, env:, &)
      end

      def fetch_formatter(headers)
        api_format = env.fetch(Grape::Env::API_FORMAT) { mime_types[headers[Rack::CONTENT_TYPE]] }
        Grape::Formatter.formatter_for(api_format, formatters)
      end

      # Set the content type header for the API format if it is not already present.
      #
      # @param headers [Hash]
      # @return [Hash]
      def ensure_content_type(headers)
        return headers if headers[Rack::CONTENT_TYPE]

        headers[Rack::CONTENT_TYPE] = content_type_for(env[Grape::Env::API_FORMAT])
        headers
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
        fmt = media_type ? mime_types[media_type] : default_format

        throw :error, Grape::Exceptions::ErrorResponse.new(status: 415, message: "The provided content-type '#{media_type}' is not supported.") unless content_type_for(fmt)
        parser = Grape::Parser.parser_for fmt, parsers
        return env[Grape::Env::API_REQUEST_BODY] = body unless parser

        begin
          body = (env[Grape::Env::API_REQUEST_BODY] = parser.call(body, env))
          if body.is_a?(Hash)
            if (form_hash = env[Rack::RACK_REQUEST_FORM_HASH])
              form_hash.merge!(body)
            else
              env[Rack::RACK_REQUEST_FORM_HASH] = body
            end
            env[Rack::RACK_REQUEST_FORM_INPUT] = env[Rack::RACK_INPUT]
          end
        rescue Grape::Exceptions::Base => e
          raise e
        rescue StandardError => e
          throw :error, Grape::Exceptions::ErrorResponse.new(status: 400, message: e.message, backtrace: e.backtrace, original_exception: e)
        end
      end

      # this middleware will not try to format the following content-types since Rack already handles them
      # when calling Rack's `params` function
      # - application/x-www-form-urlencoded
      # - multipart/form-data
      # - multipart/related
      # - multipart/mixed
      def read_body_input?
        return false unless rack_request.post? || rack_request.put? || rack_request.patch? || rack_request.delete?
        return false if rack_request.form_data? && rack_request.content_type
        return false if rack_request.parseable_data?

        rack_request.content_length.to_i.positive? || rack_request.env['HTTP_TRANSFER_ENCODING'] == 'chunked'
      end

      def negotiate_content_type
        fmt = format_from_extension || format_from_query || format || format_from_header || default_format
        return env[Grape::Env::API_FORMAT] = fmt.to_sym if content_type_for(fmt)

        throw :error, Grape::Exceptions::ErrorResponse.new(status: 406, message: "The requested format '#{fmt}' is not supported.")
      end

      def format_from_extension
        request_path = try_scrub(path_for_extension)
        dot_pos = request_path.rindex('.')
        return unless dot_pos

        extension = request_path[(dot_pos + 1)..]
        extension if content_type_for(extension)
      end

      # The extension is the tail of the request path, so PATH_INFO answers it
      # on its own whenever there is one: a dot in SCRIPT_NAME is followed by
      # the slash that opens PATH_INFO, and no registered extension holds a
      # slash. Only an empty PATH_INFO needs +Rack::Request#path+ — and with it
      # the String its concatenation allocates. Tested with +empty?+ rather
      # than +blank?+: the path is not scrubbed yet, and a regexp match on an
      # invalid byte sequence raises.
      def path_for_extension
        path_info = env[Rack::PATH_INFO]
        return rack_request.path if path_info.nil? || path_info.empty?

        path_info
      end

      # +?format=+ can only be there when there is a query string at all, so
      # the common query-less request skips parsing one.
      def format_from_query
        query_string = env[Rack::QUERY_STRING]
        return if query_string.nil? || query_string.empty?

        query_params['format']
      end

      # Media types are case-insensitive (RFC 9110 §8.3.1) but the registered
      # ones are spelled in lower case and Rack matches them literally, so an
      # `Accept: TEXT/PLAIN` found nothing and fell through to the default
      # format — the client quietly got something other than what it asked for.
      def format_from_header
        accept_header = try_scrub(env['HTTP_ACCEPT'])
        return if accept_header.blank? || accept_header == ALL_MEDIA_TYPES

        media_type = Rack::Utils.best_q_match(accept_header.downcase, mime_types.keys)
        mime_types[media_type] if media_type
      end
    end
  end
end
