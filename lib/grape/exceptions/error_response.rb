# frozen_string_literal: true

module Grape
  module Exceptions
    # The frozen payload thrown via `throw :error, ...` (or raised by `error!`
    # inside a `Grape::Exceptions::Halt`) and consumed by
    # `Middleware::Error#error_response`. Replaces the implicit-schema Hash
    # that previously circulated between throw sites and the error middleware.
    #
    # A plain frozen class rather than a +Data+: every error response builds
    # at least two (the payload, then the one +error_response+ fills the
    # defaults into), and +Data+'s constructor takes its keywords as a Hash it
    # then validates, about 450 ns apiece. A Ruby method keeps keyword
    # arguments on the stack. It answers only what is read off it: its
    # readers.
    class ErrorResponse
      MEMBERS = %i[status message headers backtrace original_exception].freeze

      attr_reader(*MEMBERS)

      def initialize(status: nil, message: nil, headers: nil, backtrace: nil, original_exception: nil)
        @status = status
        @message = message
        @headers = headers
        @backtrace = backtrace
        @original_exception = original_exception
        freeze
      end

      def to_s
        "#<#{self.class.name} status=#{status.inspect} message=#{message.inspect} headers=#{headers.inspect}>"
      end

      # The backtrace is deliberately left unset: +Exception#backtrace+ builds
      # the whole Array of location strings, and the response only renders one
      # when the API asked for it. The exception travels along, so
      # +Middleware::Error#error_response+ can still materialize it there.
      def self.from_exception(exception)
        new(
          status: exception.status,
          message: exception.message,
          headers: exception.headers,
          original_exception: exception
        )
      end

      # Normalize heterogeneous inputs into an ErrorResponse. Preserves the
      # public contract that users can still `throw :error, hash` from their
      # own middleware or `rescue_from` handlers.
      def self.coerce(input)
        case input
        when ErrorResponse
          input
        when Grape::Exceptions::Base
          from_exception(input)
        when Hash
          new(**input.slice(*MEMBERS))
        else
          new
        end
      end
    end
  end
end
