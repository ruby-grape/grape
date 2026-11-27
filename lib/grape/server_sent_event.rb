# frozen_string_literal: true

module Grape
  # One event of a +text/event-stream+ response (see Grape::Formatter::Sse),
  # for an event that carries more than its data: a type, an id the client
  # sends back in +Last-Event-ID+ when it reconnects, a reconnection delay in
  # milliseconds, or a comment.
  #
  #   Grape::ServerSentEvent.new(event: 'token', id: 42, data: { text: 'Hi' })
  #   # event: token
  #   # id: 42
  #   # data: {"text":"Hi"}
  #
  # +data+ renders as the :sse formatter renders any element: a String as it
  # is, anything else as the :json formatter renders it. Without +data+ the
  # client dispatches nothing, so an event of a comment alone keeps an idle
  # connection open, and one of +retry+ alone only sets the delay. Give
  # +data: ''+ for an event that carries nothing.
  #
  # +event+ and +id+ are one line each, and +retry+ is a whole number: a line
  # break in any of them would start a field, or an event, of its own.
  ServerSentEvent = Data.define(:data, :event, :id, :retry, :comment) do
    def initialize(data: nil, event: nil, id: nil, retry: nil, comment: nil)
      # +retry+ is a keyword, so the argument can only be read through the binding.
      delay = binding.local_variable_get(:retry)
      raise ArgumentError, "event must be one line: `#{event.inspect}`" unless one_line?(event, /[\r\n]/)
      raise ArgumentError, "id must be one line without NUL: `#{id.inspect}`" unless one_line?(id, /[\r\n\0]/)
      raise ArgumentError, "retry must be a non-negative Integer: `#{delay.inspect}`" unless delay.nil? || (delay.is_a?(Integer) && delay >= 0)

      super
    end

    private

    def one_line?(value, forbidden)
      value.nil? || !value.to_s.match?(forbidden)
    end
  end
end
