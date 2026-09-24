# frozen_string_literal: true

module Acme
  class SlowStreamer
    def each
      (1..5).each do |i|
        yield (i.to_s + "\n")
        sleep 0.3
      end
    end
  end

  class StreamData < Grape::API
    desc 'Streams data.'
    get :stream do
      stream SlowStreamer.new
      content_type 'text/event-stream'
      status 200
    end
  end
end
