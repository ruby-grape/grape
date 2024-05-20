# frozen_string_literal: true

module Grape
  module Exceptions
    class ValidationArrayErrors < Base
      attr_reader :errors

      def initialize(errors)
        super()
        @errors = errors
      end
    end
  end
end
