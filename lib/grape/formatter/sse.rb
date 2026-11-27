# frozen_string_literal: true

module Grape
  module Formatter
    # Renders server-sent events
    # (https://html.spec.whatwg.org/multipage/server-sent-events.html), the
    # +text/event-stream+ that browsers read with +EventSource+. An Array
    # renders one event per element and any other object one event. A String
    # is served as it is, taken to be an event stream already.
    #
    # An element is the data of an unnamed event: a String as it is, anything
    # else as the :json formatter renders it. A Grape::ServerSentEvent element
    # gives the event a type, an id, a reconnection delay or a comment as well.
    # Data that spans lines is sent as one +data:+ line per line, which the
    # client joins back with newlines.
    #
    # An Enumerator renders as it is read rather than up front, so the server
    # sends each event as the enumerator yields it:
    #
    #   get :completions do
    #     Enumerator.new do |events|
    #       llm.stream(params[:prompt]) { |token| events << { text: token } }
    #       events << Grape::ServerSentEvent.new(event: 'done', data: '')
    #     end
    #   end
    class Sse < Base
      LINE_BREAK = /\r\n|\r|\n/

      class << self
        def call(object, env)
          return object if object.is_a?(String)
          return Grape::ServeStream::StreamResponse.new(object.lazy.map { |element| event(element, env) }) if object.is_a?(Enumerator)
          return object.to_ary.map { |element| event(element, env) }.join if object.respond_to?(:to_ary)

          event(object, env)
        end

        private

        def event(element, env)
          return "#{field('data', data(element, env))}\n" unless element.is_a?(Grape::ServerSentEvent)

          data = data(element.data, env) unless element.data.nil?
          "#{field('', element.comment)}#{field('event', element.event)}#{field('id', element.id)}" \
            "#{field('retry', element.retry)}#{field('data', data)}\n"
        end

        def data(object, env)
          return object if object.is_a?(String)

          Formatter::Json.call(object, env)
        end

        # A field takes one line; text spanning several repeats the field once
        # per line, and a comment is a field without a name. Each line ends
        # with "\n", so text ending in a line break keeps it as a last, empty
        # line. A field left out renders as nothing.
        def field(name, value)
          return '' if value.nil?

          text = value.to_s
          return "#{name}: #{text}\n" unless text.match?(LINE_BREAK)

          text.split(LINE_BREAK, -1).map { |line| "#{name}: #{line}\n" }.join
        end
      end
    end
  end
end
