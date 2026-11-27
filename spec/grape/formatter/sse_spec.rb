# frozen_string_literal: true

describe Grape::Formatter::Sse do
  let(:app) do
    Class.new(Grape::API) do
      content_type :sse, 'text/event-stream'
      format :sse

      get(:hash) { { text: 'Hi' } }
      get(:array) { [{ id: 1 }, 'two', nil] }
      get(:empty) { [] }
      get(:string) { "event: ping\ndata: 1\n\n" }
      get(:precompiled) { [Grape::PrecompiledJson.new('{"id":1}')] }
      get(:lines) { ["a\nb", "c\r\nd\re", "f\n"] }
      get(:enumerator) { [{ id: 1 }, { id: 2 }].each }
      get(:event) { [Grape::ServerSentEvent.new(comment: 'note', event: 'token', id: 7, retry: 1000, data: { text: 'Hi' })] }
      get(:comment) { [Grape::ServerSentEvent.new(comment: "keep\nalive")] }
      get(:empty_data) { [Grape::ServerSentEvent.new(event: 'done', data: '')] }
    end
  end

  it 'renders an object as the JSON data of one event' do
    get '/hash'
    expect(last_response.content_type).to eq('text/event-stream')
    expect(last_response.body).to eq(%(data: {"text":"Hi"}\n\n))
  end

  it 'renders each element of an Array as an event of its own, a String element as it is' do
    get '/array'
    expect(last_response.body).to eq(%(data: {"id":1}\n\ndata: two\n\ndata: null\n\n))
  end

  it 'renders an empty Array as an empty body' do
    get '/empty'
    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq('')
  end

  it 'serves a String as it is' do
    get '/string'
    expect(last_response.body).to eq("event: ping\ndata: 1\n\n")
  end

  it 'serves a Grape::PrecompiledJson element as its data' do
    get '/precompiled'
    expect(last_response.body).to eq(%(data: {"id":1}\n\n))
  end

  it 'sends data that spans lines as one data line per line, whatever ends them' do
    get '/lines'
    expect(last_response.body).to eq("data: a\ndata: b\n\ndata: c\ndata: d\ndata: e\n\ndata: f\ndata: \n\n")
  end

  it 'renders each element of an Enumerator as an event of its own' do
    get '/enumerator'
    expect(last_response.content_type).to eq('text/event-stream')
    expect(last_response.body).to eq(%(data: {"id":1}\n\ndata: {"id":2}\n\n))
  end

  it 'renders the fields of a Grape::ServerSentEvent' do
    get '/event'
    expect(last_response.body).to eq(%(: note\nevent: token\nid: 7\nretry: 1000\ndata: {"text":"Hi"}\n\n))
  end

  it 'renders a comment alone, one comment line per line, with no data' do
    get '/comment'
    expect(last_response.body).to eq(": keep\n: alive\n\n")
  end

  it 'renders empty data as an empty data line' do
    get '/empty_data'
    expect(last_response.body).to eq("event: done\ndata: \n\n")
  end

  it 'streams an Enumerator, rendering each event only as Rack reads it' do
    produced = []
    api = Class.new(Grape::API) do
      content_type :sse, 'text/event-stream'
      format :sse
      get do
        Enumerator.new do |events|
          2.times do |i|
            produced << i
            events << { id: i }
          end
        end
      end
    end

    _status, _headers, body = api.call(Rack::MockRequest.env_for('/'))
    expect(produced).to be_empty

    chunks = body.enum_for(:each).to_a
    body.close if body.respond_to?(:close)
    expect(chunks).to eq([%(data: {"id":0}\n\n), %(data: {"id":1}\n\n)])
    expect(produced).to eq([0, 1])
  end

  context 'when the API declares :sse beside its default format' do
    let(:app) do
      Class.new(Grape::API) do
        content_type :json, 'application/json'
        content_type :sse, 'text/event-stream'
        default_format :json

        get { { text: 'Hi' } }
      end
    end

    it 'answers an EventSource, which accepts text/event-stream' do
      get '/', {}, 'HTTP_ACCEPT' => 'text/event-stream'
      expect(last_response.content_type).to eq('text/event-stream')
      expect(last_response.body).to eq(%(data: {"text":"Hi"}\n\n))
    end

    it 'answers anything else in the default format' do
      get '/'
      expect(last_response.content_type).to eq('application/json')
    end
  end

  context 'when the API declares no content type' do
    let(:app) do
      Class.new(Grape::API) do
        get { { text: 'Hi' } }
      end
    end

    it 'is not negotiated' do
      get '/', {}, 'HTTP_ACCEPT' => 'text/event-stream'
      expect(last_response.content_type).to eq('text/plain')
    end
  end
end
