# frozen_string_literal: true

module Grape
  module Exceptions
    class TooManyMultipartFiles < Base
      def initialize
        super(message: compose_message(:too_many_multipart_files), status: 413)
      end
    end
  end
end
