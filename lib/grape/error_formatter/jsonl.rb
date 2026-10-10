# frozen_string_literal: true

module Grape
  module ErrorFormatter
    # An error renders as the JSON error formatter renders it, ended by a
    # newline, so the body is a JSON Lines document of one line.
    class Jsonl < Json
      class << self
        def format_structured_message(structured_message)
          "#{super}\n"
        end
      end
    end
  end
end
