# frozen_string_literal: true

module Grape
  module Exceptions
    class QueryParsing < Base
      def initialize
        super(message: compose_message(:query_parsing), status: 400)
      end
    end
  end
end
