# frozen_string_literal: true

module Grape
  module Formatter
    class Json < Base
      def self.call(object, _env)
        return object.to_s if object.is_a?(Grape::PrecompiledJson)
        return object.to_json if object.respond_to?(:to_json)

        ::Grape::Json.dump(object)
      end
    end
  end
end
