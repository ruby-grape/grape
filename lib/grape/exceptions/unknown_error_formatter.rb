# frozen_string_literal: true

module Grape
  module Exceptions
    class UnknownErrorFormatter < Base
      def initialize(error_formatter_type)
        super(message: compose_message(:unknown_error_formatter, error_formatter_type:))
      end
    end
  end
end
