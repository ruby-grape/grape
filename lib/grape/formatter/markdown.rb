# frozen_string_literal: true

module Grape
  module Formatter
    class Markdown < Base
      # Md inherits this, so the format named in the error comes from the class
      # name, the way Grape::Util::Registry derives the name each class is
      # registered under.
      def self.call(object, _env)
        return object.to_markdown if object.respond_to?(:to_markdown)
        return object if object.is_a?(String)

        raise Grape::Exceptions::InvalidFormatter.new(object.class, name.demodulize.underscore)
      end
    end
  end
end
