# frozen_string_literal: true

module Grape
  module Exceptions
    # Raised internally when a +rescue_from+ handler itself raises an
    # unrecognised exception. The framework substitutes the original
    # exception with this safe stand-in for rendering, while preserving
    # the original on +env[Grape::Env::GRAPE_EXCEPTION]+ for upstream
    # observability (loggers, error trackers, etc.).
    class InternalServerError < Base
      def initialize
        super(status: 500, message: compose_message(:internal_server_error))
      end
    end
  end
end
