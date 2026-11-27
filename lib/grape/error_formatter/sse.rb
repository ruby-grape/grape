# frozen_string_literal: true

module Grape
  module ErrorFormatter
    # An error renders as one +error+ event whose data is what the JSON error
    # formatter renders, so the body is an event stream like the responses it
    # stands in for.
    class Sse < Json
      class << self
        def format_structured_message(structured_message)
          Grape::Formatter::Sse.call(Grape::ServerSentEvent.new(event: 'error', data: super), nil)
        end
      end
    end
  end
end
