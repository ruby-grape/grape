# frozen_string_literal: true

module Spec
  module Support
    module Helpers
      def content_type_header
        Grape::Http::Headers::CONTENT_TYPE
      end

      def x_cascade_header
        Grape::Http::Headers::X_CASCADE
      end
    end
  end
end
