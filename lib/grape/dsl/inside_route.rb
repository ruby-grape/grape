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
        options[:for].configuration.evaluate
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
        status = self.status(status || inheritable_setting.namespace_inheritable[:default_error_status])
        headers = additional_headers.present? ? header.merge(additional_headers) : header
        throw :error,
              message:,
              status:,
              headers:,
              backtrace:,
              original_exception:
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
        body body_message
      end

      # Set or retrieve the HTTP status code.
      #
      # @param status [Integer] The HTTP Status Code to return for this request.
      def status(status = nil)
        case status
        when Symbol
          raise ArgumentError, "Status code :#{status} is invalid." unless Rack::Utils::SYMBOL_TO_STATUS_CODE.key?(status)

          @status = Rack::Utils.status_code(status)
        when Integer
          @status = status
        when nil
          return @status if @status

          if request.post?
            201
          elsif request.delete?
            if @body.present?
              200
            else
              204
            end
          else
            200
          end
        else
          raise ArgumentError, 'Status code must be Integer or Symbol.'
        end
      end

      # Set response content-type
      def content_type(val = nil)
        if val
          header(Rack::CONTENT_TYPE, val)
        else
          header[Rack::CONTENT_TYPE]
        end
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
        status 204
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
        if value.is_a?(String)
          file_body = Grape::ServeStream::FileBody.new(value)
          @stream = Grape::ServeStream::StreamResponse.new(file_body)
        elsif !value.is_a?(NilClass)
          raise ArgumentError, 'Argument must be a file path'
        else
          stream
        end
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
        if value.is_a?(String)
          file_body = Grape::ServeStream::FileBody.new(value)
          @stream = Grape::ServeStream::StreamResponse.new(file_body)
        elsif value.respond_to?(:each)
          @stream = Grape::ServeStream::StreamResponse.new(value)
        elsif !value.is_a?(NilClass)
          raise ArgumentError, 'Stream object must respond to :each.'
        else
          @stream
        end
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
    end
  end
end
