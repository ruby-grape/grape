# frozen_string_literal: true

module Grape
  module ServeStream
    # A simple class used to identify responses which represent streams (or files) and do not
    # need to be formatted or pre-read by Rack::Response
    class StreamResponse
      attr_reader :stream

      # @param stream [Object]
      def initialize(stream)
        @stream = stream
      end

      # Equality provided mostly for tests.
      #
      # @return [Boolean]
      def ==(other)
        stream == other.stream
      end
    end
  end
end
