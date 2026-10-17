# frozen_string_literal: true

module Grape
  module Parser
    # Parses a JSON Lines body into an Array of its values. Like a JSON body
    # that is an Array, it is left in +env['api.request.body']+ rather than
    # merged into +params+, which only takes a Hash.
    #
    # Blank lines are skipped, so a body may end with a newline or not, and
    # its lines may end in CRLF.
    class Jsonl < Base
      def self.call(object, _env)
        object.each_line.reject { |line| line.strip.empty? }.map { |line| ::Grape::Json.parse(line) }
      rescue ::Grape::Json::ParseError
        raise Grape::Exceptions::InvalidMessageBody.new('application/jsonl')
      end
    end
  end
end
