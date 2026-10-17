# frozen_string_literal: true

module Grape
  module Formatter
    # Renders JSON Lines (https://jsonlines.org): one JSON value per line, each
    # line ended by a newline. An Array renders one line per element, and any
    # other object one line. A String is served as it is, taken to be JSON
    # Lines already.
    #
    # An Enumerator renders as it is read rather than up front, so the server
    # streams each line as the enumerator yields its element:
    #
    #   get :export do
    #     User.find_each # without a block, an Enumerator
    #   end
    class Jsonl < Base
      class << self
        def call(object, env)
          return object if object.is_a?(String)
          return Grape::ServeStream::StreamResponse.new(object.lazy.map { |element| line(element, env) }) if object.is_a?(Enumerator)
          return object.to_ary.map { |element| line(element, env) }.join if object.respond_to?(:to_ary)

          line(object, env)
        end

        private

        def line(object, env)
          "#{Formatter::Json.call(object, env)}\n"
        end
      end
    end
  end
end
