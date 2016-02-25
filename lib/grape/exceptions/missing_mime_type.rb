# encoding: utf-8
module Grape
  module Exceptions
    class MissingMimeType < Base
      def initialize(new_format)
        super(message: compose_message(:missing_mime_type, new_format: new_format))
      end
    end
  end
end
