# frozen_string_literal: true

describe Grape::PrecompiledJson do
  describe '#to_s' do
    it 'returns a String value untouched' do
      json = '{"a":1,"b":[2,3]}'
      expect(described_class.new(json).to_s).to be(json)
    end

    it 'joins an Array into a JSON array without parsing its members' do
      expect(described_class.new(['{"id":1}', '{"id":2}']).to_s).to eq('[{"id":1},{"id":2}]')
    end

    it 'accepts members that are themselves precompiled' do
      members = [described_class.new('{"id":1}'), described_class.new('{"id":2}')]
      expect(described_class.new(members).to_s).to eq('[{"id":1},{"id":2}]')
    end

    it 'renders an empty Array as an empty JSON array' do
      expect(described_class.new([]).to_s).to eq('[]')
    end

    it 'does not check that the String holds JSON' do
      expect(described_class.new('not json at all').to_s).to eq('not json at all')
    end

    it 'raises for a value it cannot serve' do
      expect { described_class.new(a: 1).to_s }
        .to raise_error(Grape::Exceptions::InvalidFormatter, /cannot convert Hash to json/)
    end

    it 'raises for nil rather than serving an empty body' do
      expect { described_class.new(nil).to_s }
        .to raise_error(Grape::Exceptions::InvalidFormatter, /cannot convert NilClass to json/)
    end
  end

  describe 'through the JSON formatters' do
    it 'is served verbatim by the json formatter' do
      expect(Grape::Formatter::Json.call(described_class.new('{"a":1}'), {})).to eq('{"a":1}')
    end

    it 'is served verbatim by the serializable_hash formatter' do
      expect(Grape::Formatter::SerializableHash.call(described_class.new('{"a":1}'), {})).to eq('{"a":1}')
    end

    it 'leaves an unwrapped String encoded as before' do
      expect(Grape::Formatter::Json.call('hello', {})).to eq('"hello"')
    end

    it 'leaves an unwrapped Hash encoded as before' do
      expect(Grape::Formatter::Json.call({ a: 1 }, {})).to eq('{"a":1}')
    end
  end

  describe 'in an endpoint' do
    include Rack::Test::Methods

    let(:app) do
      Class.new(Grape::API) do
        format :json

        get('/cached') { body Grape::PrecompiledJson.new('{"a":1,"b":[2,3]}') }
        get('/collection') { body Grape::PrecompiledJson.new(['{"id":1}', '{"id":2}']) }
        get('/plain') { 'hello' }
        get('/oops') { body Grape::PrecompiledJson.new(a: 1) }
        get('/boom') { error!('nope', 422) }
      end
    end

    it 'serves pre-rendered JSON without encoding it twice' do
      get '/cached'

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('{"a":1,"b":[2,3]}')
      expect(last_response.content_type).to eq('application/json')
    end

    it 'splices a collection of rendered blobs' do
      get '/collection'

      expect(last_response.body).to eq('[{"id":1},{"id":2}]')
    end

    it 'still encodes an unwrapped body' do
      get '/plain'

      expect(last_response.body).to eq('"hello"')
    end

    it 'answers 500 rather than handing Rack a body it cannot serve' do
      get '/oops'

      expect(last_response.status).to eq(500)
      expect(last_response.body).to include('cannot convert Hash to json')
    end

    it 'leaves error bodies to the error formatter' do
      get '/boom'

      expect(last_response.status).to eq(422)
      expect(last_response.body).to eq('{"error":"nope"}')
    end
  end
end
