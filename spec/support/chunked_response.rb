# frozen_string_literal: true

# this is a copy of Rack::Chunked which has been removed in rack > 3.0

class ChunkedResponse
  class Body
    TERM = "\r\n"
    TAIL = "0#{TERM}"

    # Store the response body to be chunked.
    def initialize(body)
      @body = body
    end

    # For each element yielded by the response body, yield
    # the element in chunked encoding.
    def each(&block)
      term = TERM
      @body.each do |chunk|
        size = chunk.bytesize
        next if size == 0

        yield [size.to_s(16), term, chunk.b, term].join
      end
      yield TAIL
      yield_trailers(&block)
      yield term
    end

    # Close the response body if the response body supports it.
    def close
      @body.close if @body.respond_to?(:close)
    end

    private

    # Do nothing as this class does not support trailer headers.
    def yield_trailers
    end
  end

  class TrailerBody < Body
    private

    # Yield strings for each trailer header.
    def yield_trailers
      @body.trailers.each_pair do |k, v|
        yield "#{k}: #{v}\r\n"
      end
    end
  end

  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = response = @app.call(env)

    if !Rack::Utils::STATUS_WITH_NO_ENTITY_BODY.key?(status.to_i) &&
      !headers[Rack::CONTENT_LENGTH] &&
      !headers[Rack::TRANSFER_ENCODING]

      headers[Rack::TRANSFER_ENCODING] = 'chunked'
      if headers['trailer']
        response[2] = TrailerBody.new(body)
      else
        response[2] = Body.new(body)
      end
    end

    response
  end
end
