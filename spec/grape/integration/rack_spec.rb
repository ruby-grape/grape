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

  # https://github.com/ruby-grape/grape/issues/2487
  describe 'multipart tempfiles' do
    let(:uploaded_paths) { [] }
    let(:upload) { Rack::Test::UploadedFile.new(__FILE__, 'text/plain') }

    let(:app) do
      paths = uploaded_paths
      Class.new(Grape::API) do
        params do
          requires :file, type: File
        end

        post 'upload' do
          paths << params[:file][:tempfile].path
          'ok'
        end

        post 'failed_upload' do
          paths << params[:file][:tempfile].path
          error!('failed', 422)
        end

        post 'raising_upload' do
          paths << params[:file][:tempfile].path
          raise ArgumentError, 'boom'
        end
      end
    end

    it 'unlinks the tempfile once the response is closed' do
      post '/upload', file: upload
      expect(last_response.body).to eq('ok')
      expect(uploaded_paths.size).to eq(1)
      expect(File.exist?(uploaded_paths.first)).to be(false)
    end

    it 'unlinks the tempfile when the endpoint returns an error' do
      post '/failed_upload', file: upload
      expect(last_response.status).to eq(422)
      expect(uploaded_paths.size).to eq(1)
      expect(File.exist?(uploaded_paths.first)).to be(false)
    end

    it 'unlinks the tempfile when an exception escapes the API' do
      expect { post '/raising_upload', file: upload }.to raise_error(ArgumentError, 'boom')
      expect(uploaded_paths.size).to eq(1)
      expect(File.exist?(uploaded_paths.first)).to be(false)
    end

    context 'when the route that read the upload cascades' do
      let(:app) do
        paths = uploaded_paths
        declines = Class.new(Grape::API) do
          post 'upload' do
            paths << params[:file][:tempfile].path
            error!('not mine', 404, 'X-Cascade' => 'pass')
          end
        end
        answers = Class.new(Grape::API) do
          post('upload') { params[:file][:tempfile].read.bytesize.to_s }
        end
        Class.new(Grape::API) do
          mount declines
          mount answers
        end
      end

      it 'leaves the tempfile open for the next route and unlinks it once the response is closed' do
        post '/upload', file: upload
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq(File.size(__FILE__).to_s)
        expect(uploaded_paths.size).to eq(1)
        expect(File.exist?(uploaded_paths.first)).to be(false)
      end
    end

    context 'when a mounted Rack app reads the upload' do
      let(:app) do
        paths = uploaded_paths
        rack_app = lambda do |env|
          paths << Rack::Request.new(env).POST['file'][:tempfile].path
          [200, { 'content-type' => 'text/plain' }, ['ok']].freeze
        end
        Class.new(Grape::API) do
          mount rack_app => '/rack'
        end
      end

      it 'unlinks the tempfile once the response is closed' do
        post '/rack', file: upload
        expect(last_response.body).to eq('ok')
        expect(uploaded_paths.size).to eq(1)
        expect(File.exist?(uploaded_paths.first)).to be(false)
      end
    end

    context 'when Rack::TempfileReaper wraps the API too, as in a Rails application' do
      let(:grape_api) do
        paths = uploaded_paths
        Class.new(Grape::API) do
          post 'upload' do
            paths << params[:file][:tempfile].path
            'ok'
          end
        end
      end
      let(:app) { Rack::TempfileReaper.new(grape_api) }

      it 'unlinks the tempfile once the response is closed' do
        post '/upload', file: upload
        expect(last_response.body).to eq('ok')
        expect(uploaded_paths.size).to eq(1)
        expect(File.exist?(uploaded_paths.first)).to be(false)
      end
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
