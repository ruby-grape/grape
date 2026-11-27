# frozen_string_literal: true

if defined?(Falcon)
  require 'async/http/client'
  require 'async/http/endpoint'
end

# Grape behind a real Falcon server. Every request runs in a fiber on the same
# thread, and requests interleave whenever an endpoint waits, so state Grape
# kept per thread or on a shared object would leak from one request into the
# next.
describe 'Falcon', if: defined?(Falcon) do
  # Serves +app+ from Falcon on a free local port and yields a client
  # connected to it. The timeout turns a request that never completes into a
  # failure rather than a hung build.
  def serve(app)
    Sync do |task|
      bound = Async::HTTP::Endpoint.parse('http://127.0.0.1:0').bound
      server_task = task.async { falcon(app, bound).run }
      client = client_for(bound)
      task.with_timeout(5) { yield client }
    ensure
      client&.close
      server_task&.stop
      bound&.close
    end
  end

  # Falcon's response cache would answer a repeated GET without Grape.
  def falcon(app, bound)
    Falcon::Server.new(Falcon::Server.rack_middleware(app, cache: false), bound, protocol: Async::HTTP::Protocol::HTTP, scheme: 'http')
  end

  def client_for(bound)
    port = bound.sockets.first.to_io.local_address.ip_port
    Async::HTTP::Client.new(Async::HTTP::Endpoint.parse("http://127.0.0.1:#{port}"))
  end

  describe 'concurrent requests' do
    let(:pausing_validator) do
      Class.new(Grape::Validations::Validators::Base) do
        def validate_param!(attr_name, params)
          sleep(0)
          return unless params[attr_name] == 'bad'

          raise Grape::Exceptions::Validation.new(params: [@scope.full_name(attr_name)], message: 'is bad')
        end
      end
    end

    before do
      stub_const('PausingValidator', pausing_validator)
      Grape::Validations.register(PausingValidator)
    end

    after { Grape::Validations.deregister(:pausing) }

    it 'keeps each request to its own params, endpoint and validation errors' do
      in_flight = 0
      most_in_flight = 0
      app = Class.new(Grape::API) do
        format :json
        before do
          in_flight += 1
          most_in_flight = [most_in_flight, in_flight].max
          @id = params[:id]
          sleep(0)
        end

        after do
          sleep(0)
          header 'X-Id', @id.to_s
        end

        finally { in_flight -= 1 }
        params do
          requires :id, type: Integer
          # The pause inside an element is what exposes a shared index
          # tracker: the error names the element by its index.
          requires :items, type: Array do
            requires :value, type: String, pausing: true
          end
        end
        post('/items') do
          sleep(0)
          { id: params[:id], before: @id }
        end
      end

      ids = (0...30).to_a
      responses = serve(app) do |client|
        ids.map do |id|
          items = Array.new(4) { { value: 'ok' } }
          items[id % 4][:value] = 'bad' if id.odd?
          Async do
            response = client.post('/items', [%w[content-type application/json]], { id:, items: }.to_json)
            [response.status, response.headers['x-id']&.first, response.read]
          end
        end.map(&:wait)
      end

      expect(responses).to eq(
        ids.map do |id|
          next [400, nil, { error: "items[#{id % 4}][value] is bad" }.to_json] if id.odd?

          [201, id.to_s, { id:, before: id }.to_json]
        end
      )
      expect(most_in_flight).to be > 1
    end
  end

  describe 'error! in a task the route waits on' do
    it 'responds with its status' do
      app = Class.new(Grape::API) do
        format :json
        get('/') do
          Async do
            # A lookup that takes a moment, so the route is already waiting
            # when error! raises; async logs a failure nobody waits on.
            sleep(0.01)
            error!('out of stock', 409)
          end.wait
        end
      end

      response = serve(app) { |client| client.get('/').then { |r| [r.status, r.read] } }

      expect(response).to eq([409, { error: 'out of stock' }.to_json])
    end

    it 'responds with its status under rescue_from :all' do
      app = Class.new(Grape::API) do
        format :json
        rescue_from :all
        get('/') do
          Async do
            # A lookup that takes a moment, so the route is already waiting
            # when error! raises; async logs a failure nobody waits on.
            sleep(0.01)
            error!('out of stock', 409)
          end.wait
        end
      end

      response = serve(app) { |client| client.get('/').then { |r| [r.status, r.read] } }

      expect(response).to eq([409, { error: 'out of stock' }.to_json])
    end
  end

  describe 'stream' do
    it 'sends each chunk before the endpoint produces the next' do
      received = Async::Queue.new
      acknowledged = []
      app = Class.new(Grape::API) do
        get('/') do
          # After each chunk the endpoint waits for the client to have it. A
          # body read in full before it is sent gets no acknowledgement, and
          # the timeout keeps that from hanging the endpoint.
          stream(Enumerator.new do |yielder|
            3.times do |index|
              yielder << "chunk #{index}\n"
              acknowledged << received.dequeue(timeout: 1)
            end
          end)
        end
      end

      chunks = serve(app) do |client|
        client.get('/').body.to_enum(:each).map do |chunk|
          received.enqueue(chunk)
          chunk
        end
      end

      expect(chunks).to eq(["chunk 0\n", "chunk 1\n", "chunk 2\n"])
      expect(acknowledged).to eq(chunks)
    end
  end
end
