# frozen_string_literal: true

describe Grape::Parser::Json, if: !defined?(MultiJson) do
  include Rack::Test::Methods

  let(:app) do
    Class.new(Grape::API) do
      format :json

      post '/data' do
        params.to_h
      end
    end
  end

  # Verify that json_class payloads are treated as plain data and do not
  # trigger Ruby object instantiation. JSON.parse never honours the json_class
  # additions mechanism (unlike JSON.load), so the named class is never built.
  context 'when the request body contains a json_class key' do
    let(:triggered) { [] }

    before do
      t = triggered
      stub_const('JsonClassTarget', Class.new do
        define_singleton_method(:json_create) do |_data|
          t << true
          new
        end
      end)
    end

    it 'does not instantiate the named class' do
      body = JSON.dump('json_class' => 'JsonClassTarget', 'data' => { 'x' => 1 })
      post '/data', body, 'CONTENT_TYPE' => 'application/json'

      expect(triggered).to be_empty
    end

    it 'returns the payload as a plain hash' do
      body = JSON.dump('json_class' => 'JsonClassTarget', 'data' => { 'x' => 1 })
      post '/data', body, 'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(201)
      parsed = JSON.parse(last_response.body)
      expect(parsed['json_class']).to eq('JsonClassTarget')
    end
  end
end
