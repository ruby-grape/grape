# frozen_string_literal: true

describe Rack do
  it 'correctly populates params from a Tempfile' do
    input = Tempfile.new 'rubbish'
    begin
      app = Class.new(Grape::API) do
        format :json
        post do
          { params_keys: params.keys }
        end
      end
      input.write({ test: '123' * 10_000 }.to_json)
      input.rewind
      options = {
        input: input,
        method: 'POST',
        'CONTENT_TYPE' => 'application/json'
      }
      env = Rack::MockRequest.env_for('/', options)

      expect(JSON.parse(read_chunks(app.call(env)[2]).join)['params_keys']).to match_array('test')
    ensure
      input.close
      input.unlink
    end
  end

  context 'when the app is mounted' do
    let(:ping_mount) do
      Class.new(Grape::API) do
        get 'ping'
      end
    end

    let(:app) do
      app_to_mount = ping_mount
      app = Class.new(Grape::API) do
        namespace 'namespace' do
          mount app_to_mount
        end
      end
      Rack::Builder.new(app)
    end

    it 'finds the app on the namespace' do
      get '/namespace/ping'
      expect(last_response.status).to eq 200
    end
  end
end
