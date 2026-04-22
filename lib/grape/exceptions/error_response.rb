# frozen_string_literal: true

module Grape
  module Exceptions
    # Value object representing the payload thrown via `throw :error, ...`
    # and consumed by `Middleware::Error#error_response`. Replaces the
    # implicit-schema Hash that previously circulated between throw sites
    # and the error middleware.
    class ErrorResponse
      attr_reader :status, :message, :headers, :backtrace, :original_exception

      def initialize(status: nil, message: nil, headers: nil, backtrace: nil, original_exception: nil)
        @status = status
        @message = message
        @headers = headers
        @backtrace = backtrace
        @original_exception = original_exception
      end

      def to_s
        "#<#{self.class.name} status=#{status.inspect} message=#{message.inspect} headers=#{headers.inspect}>"
      end

      def ==(other)
        eql?(other)
      end

      def eql?(other)
        self.class == other.class &&
          other.status == status &&
          other.message == message &&
          other.headers == headers &&
          other.backtrace == backtrace &&
          other.original_exception == original_exception
      end

      def hash
        [self.class, status, message, headers, backtrace, original_exception].hash
      end

      def self.from_exception(exception)
        new(
          status: exception.status,
          message: exception.message,
          headers: exception.headers,
          backtrace: exception.backtrace,
          original_exception: exception
        )
      end

      # Normalize heterogeneous inputs into an ErrorResponse. Preserves the
      # public contract that users can still `throw :error, hash` from their
      # own middleware or `rescue_from` handlers.
      def self.coerce(input)
        case input
        when ErrorResponse           then input
        when Grape::Exceptions::Base then from_exception(input)
        when Hash                    then new(**input.slice(:status, :message, :headers, :backtrace, :original_exception))
        else                              new
        end
      end
    end
  end
end
