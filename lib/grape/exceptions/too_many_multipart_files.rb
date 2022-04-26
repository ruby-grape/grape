# frozen_string_literal: true

module Grape
  module Exceptions
    class TooManyMultipartFiles < Base
      def initialize(limit)
        super(message: compose_message(:too_many_multipart_files, limit: limit), status: 413)
      end
    end
  end
end
