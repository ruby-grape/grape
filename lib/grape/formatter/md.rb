# frozen_string_literal: true

module Grape
  module Formatter
    class Md < Base
      FORMAT = 'md'

      def self.call(object, _env)
        return object.to_markdown if object.respond_to?(:to_markdown)
        return object if object.is_a?(String)

        raise Grape::Exceptions::InvalidFormatter.new(object.class, self::FORMAT)
      end
    end
  end
end
