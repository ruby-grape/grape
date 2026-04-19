# frozen_string_literal: true

module Grape
  module Exceptions
    class ValidationArrayErrors < Base
      EMPTY_BACKTRACE = [].freeze

      attr_reader :errors

      def initialize(errors)
        super()
        @errors = errors
        # Skip backtrace capture — see Grape::Exceptions::Validation for rationale.
        set_backtrace(EMPTY_BACKTRACE)
      end
    end
  end
end
