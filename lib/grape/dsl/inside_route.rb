# frozen_string_literal: true

module Grape
  module DSL
    module InsideRoute
      include Declared
      include Entity

      # Backward compatibility: alias exception class to previous location
      MethodNotYetAvailable = Declared::MethodNotYetAvailable

      # The API version as specified in the URL.
      def version
        env[Grape::Env::API_VERSION]
      end

      def configuration
        config.api.configuration.evaluate
      end

      # End the request and display an error to the
      # end user with the specified message.
      #
      # @param message [String] The message to display.
      # @param status [Integer] The HTTP Status Code. Defaults to default_error_status, 500 if not set.
      # @param additional_headers [Hash] Addtional headers for the response.
      # @param backtrace [Array<String>] The backtrace of the exception that caused the error.
      # @param original_exception [Exception] The original exception that caused the error.
      def error!(message, status = nil, additional_headers = nil, backtrace = nil, original_exception = nil)
        resolved_status = self.status(status || inheritable_setting.default_error_status)
        headers = additional_headers.present? ? header.merge(additional_headers) : header
        throw :error, Grape::Exceptions::ErrorResponse.new(
          message:, status: resolved_status, headers:, backtrace:, original_exception:
        )
      end

      # Redirect to a new url.
      #
      # @param url [String] The url to be redirect.
      # @param permanent [Boolean] default false.
      # @param body default a short message including the URL.
      def redirect(url, permanent: false, body: nil)
        body_message = body
        if permanent
          status 301
          body_message ||= "This resource has been moved permanently to #{url}."
        elsif http_version == 'HTTP/1.1' && !request.get?
          status 303
          body_message ||= "An alternate resource is located at #{url}."
        else
          status 302
          body_message ||= "This resource has been moved temporarily to #{url}."
        end
        header 'Location', url
        content_type 'text/plain'
        # Render the message Grape generated as the plain text it is. Setting
        # only the header left it to the API's own formatter, which on a JSON
        # API returned the sentence wrapped in quotes under a text/plain content
        # type. A caller-supplied body keeps the API's format: it may be
        # structured, and the txt formatter would render a Hash through `to_s`.
        api_format :txt unless body
        body body_message
      end

      # Set or retrieve the HTTP status code.
      #
      # @param status [Integer] The HTTP Status Code to return for this request.
      def status(status = nil)
        return @status || default_status if status.nil?

        case status
        when Symbol, Integer
          @status = Rack::Utils.status_code(status)
        else
          raise ArgumentError, 'Status code must be Integer or Symbol.'
        end
      end

      # Set response content-type
      def content_type(val = nil)
        return header(Rack::CONTENT_TYPE, val) if val

        header[Rack::CONTENT_TYPE]
      end

      # Allows you to define the response body as something other than the
      # return value.
      #
      # @example
      #   get '/body' do
      #     body "Body"
      #     "Not the Body"
      #   end
      #
      #   GET /body # => "Body"
      def body(value = nil)
        if value
          @body = value
        elsif value == false
          @body = ''
          status 204
        else
          @body
        end
      end

      # Allows you to explicitly return no content.
      #
      # @example
      #   delete :id do
      #     return_no_content
      #     "not returned"
      #   end
      #
      #   DELETE /12 # => 204 No Content, ""
      def return_no_content
        body false
      end

      # Allows you to send a file to the client via sendfile.
      #
      # @example
      #   get '/file' do
      #     sendfile FileStreamer.new(...)
      #   end
      #
      #   GET /file # => "contents of file"
      def sendfile(value = nil)
        return stream if value.nil?

        raise ArgumentError, 'Argument must be a file path' unless value.is_a?(String)

        file_body = Grape::ServeStream::FileBody.new(value)
        @stream = Grape::ServeStream::StreamResponse.new(file_body)
      end

      # Allows you to define the response as a streamable object.
      #
      # If Content-Length and Transfer-Encoding are blank (among other conditions),
      # Rack assumes this response can be streamed in chunks.
      #
      # @example
      #   get '/stream' do
      #     stream FileStreamer.new(...)
      #   end
      #
      #   GET /stream # => "chunked contents of file"
      #
      # See:
      # * https://github.com/rack/rack/blob/99293fa13d86cd48021630fcc4bd5acc9de5bdc3/lib/rack/chunked.rb
      # * https://github.com/rack/rack/blob/99293fa13d86cd48021630fcc4bd5acc9de5bdc3/lib/rack/etag.rb
      def stream(value = nil)
        return if value.nil? && @stream.nil?

        header Rack::CONTENT_LENGTH, nil
        header 'Transfer-Encoding', nil
        header Rack::CACHE_CONTROL, 'no-cache' # Skips ETag generation (reading the response up front)

        return @stream if value.nil?

        @stream = Grape::ServeStream::StreamResponse.new(stream_body(value))
      end

      # Returns route information for the current request.
      #
      # @example
      #
      #   desc "Returns the route description."
      #   get '/' do
      #     route.description
      #   end
      def route
        env[Grape::Env::GRAPE_ROUTING_ARGS][:route_info]
      end

      def http_version
        env.fetch('HTTP_VERSION') { env[Rack::SERVER_PROTOCOL] }
      end

      def api_format(format)
        env[Grape::Env::API_FORMAT] = format
      end

      def context
        self
      end

      private

      # Wraps a stream +value+ into a body that responds to +:each+.
      def stream_body(value)
        return Grape::ServeStream::FileBody.new(value) if value.is_a?(String)

        raise ArgumentError, 'Stream object must respond to :each.' unless value.respond_to?(:each)

        value
      end

      # The default HTTP status when none has been set explicitly.
      # Reads the request method once instead of asking through +post?+ and
      # +delete?+, each of which reads it again. Every response that did not set
      # a status of its own comes through here, so it is read straight off the
      # env: +Grape::Request+ wraps the very same Hash and answers
      # +request_method+ with the same lookup, two method calls further down.
      def default_status
        request_method = env[Rack::REQUEST_METHOD]
        return 201 if request_method == Rack::POST
        return 204 if request_method == Rack::DELETE && @body.blank?

        200
      end
    end
  end
end
