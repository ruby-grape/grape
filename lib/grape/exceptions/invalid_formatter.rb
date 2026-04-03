# frozen_string_literal: true

module Grape
  module Exceptions
    class InvalidFormatter < Base
      def initialize(klass, to_format)
        super(message: compose_message(:invalid_formatter, klass:, to_format:))
      end
    end
  end
end
