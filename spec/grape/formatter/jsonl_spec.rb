# frozen_string_literal: true

describe Grape::Formatter::Jsonl do
  let(:app) do
    Class.new(Grape::API) do
      content_type :jsonl, 'application/jsonl'
      format :jsonl

      get(:hash) { { id: 1 } }
      get(:array) { [{ id: 1 }, 'two', nil] }
      get(:empty) { [] }
      get(:string) { %({"id":1}\n{"id":2}\n) }
      get(:precompiled) { [Grape::PrecompiledJson.new('{"id":1}')] }
      get(:enumerator) { [{ id: 1 }, { id: 2 }].each }
    end
  end

  it 'renders an object as one line' do
    get '/hash'
    expect(last_response.content_type).to eq('application/jsonl')
    expect(last_response.body).to eq(%({"id":1}\n))
  end

  it 'renders each element of an Array as a line of its own' do
    get '/array'
    expect(last_response.body).to eq(%({"id":1}\n"two"\nnull\n))
  end

  it 'renders an empty Array as an empty body' do
    get '/empty'
    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq('')
  end

  it 'serves a String as it is' do
    get '/string'
    expect(last_response.body).to eq(%({"id":1}\n{"id":2}\n))
  end

  it 'serves a Grape::PrecompiledJson element as its line' do
    get '/precompiled'
    expect(last_response.body).to eq(%({"id":1}\n))
  end

  it 'renders each element of an Enumerator as a line of its own' do
    get '/enumerator'
    expect(last_response.content_type).to eq('application/jsonl')
    expect(last_response.body).to eq(%({"id":1}\n{"id":2}\n))
  end

  it 'streams an Enumerator, rendering each element only as Rack reads it' do
    produced = []
    api = Class.new(Grape::API) do
      content_type :jsonl, 'application/jsonl'
      format :jsonl
      get do
        Enumerator.new do |lines|
          2.times do |i|
            produced << i
            lines << { id: i }
          end
        end
      end
    end

    _status, _headers, body = api.call(Rack::MockRequest.env_for('/'))
    expect(produced).to be_empty

    chunks = body.enum_for(:each).to_a
    body.close if body.respond_to?(:close)
    expect(chunks).to eq([%({"id":0}\n), %({"id":1}\n)])
    expect(produced).to eq([0, 1])
  end

  context 'with a content type registered for :jsonl' do
    let(:app) do
      Class.new(Grape::API) do
        content_type :jsonl, 'application/x-ndjson'
        format :jsonl

        get { [{ id: 1 }, { id: 2 }] }
      end
    end

    it 'renders under that content type' do
      get '/'
      expect(last_response.content_type).to eq('application/x-ndjson')
      expect(last_response.body).to eq(%({"id":1}\n{"id":2}\n))
    end
  end

  context 'when the API declares no content type' do
    let(:app) do
      Class.new(Grape::API) do
        get { { id: 1 } }
      end
    end

    it 'is not negotiated' do
      get '/', {}, 'HTTP_ACCEPT' => 'application/jsonl'
      expect(last_response.content_type).to eq('text/plain')
    end
  end
end
