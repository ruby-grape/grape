# frozen_string_literal: true

module Grape
  module Exceptions
    class RequestError < Base
      def initialize(status: 400)
        super(message: $ERROR_INFO&.message, status:)
      end
    end
  end
end
