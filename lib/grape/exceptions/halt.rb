# frozen_string_literal: true

module Grape
  module Exceptions
    # Raised by +error!+ to end the request with an error response. It carries
    # the ErrorResponse a +throw :error+ carries, and +Middleware::Error+
    # renders it the same way: as it is, without consulting +rescue_from+.
    #
    # It is raised rather than thrown so that it leaves a block the way an
    # exception does. Active Record rolls a transaction back only when an
    # exception leaves its block, and commits it on a +throw+. A +throw+ cannot
    # leave the fiber or thread it was thrown in either, while +Async::Task#wait+
    # and +Thread#value+ re-raise an exception in the request's own.
    #
    # A StandardError on purpose: async treats any other exception leaving a
    # task as fatal and stops its reactor. It is not a Grape::Exceptions::Base,
    # so a +rescue+ of those around +error!+ still lets it through.
    class Halt < StandardError
      extend Forwardable

      EMPTY_BACKTRACE = [].freeze

      attr_reader :response

      def_delegators :response, :status, :headers

      # Keywords spelled out rather than forwarded with **, which would gather
      # them into a Hash on every error! only to spread it again.
      def initialize(status: nil, message: nil, headers: nil, backtrace: nil, original_exception: nil)
        @response = ErrorResponse.new(status:, message:, headers:, backtrace:, original_exception:)
        super(message)
        # Pre-seed the backtrace so Ruby's raise skips capture, as
        # Grape::Exceptions::Validation does: +error!+ is how a route answers
        # with an error, and the backtrace would only point at that route.
        set_backtrace(EMPTY_BACKTRACE)
      end
    end
  end
end
