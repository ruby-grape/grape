# frozen_string_literal: true

module Grape
  module Formatter
    class Txt < Base
      def self.call(object, _env)
        object.respond_to?(:to_txt) ? object.to_txt : object.to_s
      end
    end
  end
end
