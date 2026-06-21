# frozen_string_literal: true

module Grape
  module Formatter
    class Json < Base
      def self.call(object, _env)
        ::Grape::Json.dump(object)
      end
    end
  end
end
