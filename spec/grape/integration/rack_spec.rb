# frozen_string_literal: true

describe Rack do
  describe 'from a Tempfile' do
    subject { last_response.body }

    let(:app) do
      Class.new(Grape::API) do
        format :json

        params do
          requires :file, type: File
        end

        post do
          params[:file].then do |file|
            {
              filename: file[:filename],
              type: file[:type],
              content: file[:tempfile].read
            }
          end
        end
      end
    end

    let(:response_body) do
      {
        filename: File.basename(tempfile.path),
        type: 'text/plain',
        content: 'rubbish'
      }.to_json
    end

    let(:tempfile) do
      Tempfile.new.tap do |t|
        t.write('rubbish')
        t.rewind
      end
    end

    before do
      post '/', file: Rack::Test::UploadedFile.new(tempfile.path, 'text/plain')
    end

    it 'correctly populates params from a Tempfile' do
      expect(subject).to eq(response_body)
    ensure
      tempfile.close!
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
      Class.new(Grape::API) do
        namespace 'namespace' do
          mount app_to_mount
        end
      end
    end

    it 'finds the app on the namespace' do
      get '/namespace/ping'
      expect(last_response).to be_successful
    end
  end

  # https://github.com/ruby-grape/grape/issues/2576
  describe 'when an api is mounted' do
    let(:api) do
      Class.new(Grape::API) do
        format :json
        version 'v1', using: :path

        resource :system do
          get :ping do
            { message: 'pong' }
          end
        end
      end
    end

    let(:parent_api) do
      api_to_mount = api
      Class.new(Grape::API) do
        format :json
        namespace '/api' do
          mount api_to_mount
        end
      end
    end

    it 'is not polluted with the parent namespace' do
      env = Rack::MockRequest.env_for('/v1/api/system/ping', method: 'GET')
      response = Rack::MockResponse[*parent_api.call(env)]

      expect(response.status).to eq(200)
      parsed_body = JSON.parse(response.body)
      expect(parsed_body['message']).to eq('pong')
    end

    it 'can call the api' do
      env = Rack::MockRequest.env_for('/v1/system/ping', method: 'GET')
      response = Rack::MockResponse[*api.call(env)]

      expect(response.status).to eq(200)
      parsed_body = JSON.parse(response.body)
      expect(parsed_body['message']).to eq('pong')
    end
  end
end
