# frozen_string_literal: true

describe Grape::Endpoint do
  subject { Class.new(Grape::API) }

  def app
    subject
  end

  before do
    subject.namespace :api do
      get ':id(/:ext)' do
        [params[:id], params[:ext]].compact.join('/')
      end

      put ':id' do
        params[:id]
      end
    end
  end

  context 'get' do
    it 'responds without ext' do
      get '/api/foo'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq 'foo'
    end

    it 'responds with ext' do
      get '/api/foo/bar'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq 'foo/bar'
    end
  end

  context 'put' do
    it 'responds' do
      put '/api/foo'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq 'foo'
    end
  end

  describe 'a path opening with an optional segment' do
    %w[(:type) /(:type) (/:type)].each do |spelling|
      context "when spelled #{spelling} in a namespace" do
        subject do
          Class.new(Grape::API) do
            namespace(:root) { get(spelling) { "type=#{params[:type]}" } }
          end
        end

        it 'answers the namespace path, with or without the segment' do
          get '/root'
          expect(last_response.body).to eq('type=')

          get '/root/x'
          expect(last_response.body).to eq('type=x')
        end
      end
    end

    context 'when it is a nested namespace' do
      subject do
        Class.new(Grape::API) do
          namespace(:root) { namespace('(:type)') { get { "type=#{params[:type]}" } } }
        end
      end

      it 'answers the outer namespace path, with or without the segment' do
        get '/root'
        expect(last_response.body).to eq('type=')

        get '/root/x'
        expect(last_response.body).to eq('type=x')
      end
    end

    context 'when it follows a prefix and a path version' do
      subject do
        Class.new(Grape::API) do
          prefix :api
          version 'v1', using: :path
          get('(:type)') { "type=#{params[:type]}" }
        end
      end

      it 'answers the version path, with or without the segment' do
        get '/api/v1'
        expect(last_response.body).to eq('type=')

        get '/api/v1/x'
        expect(last_response.body).to eq('type=x')
      end
    end

    context 'when it follows a mount path' do
      subject do
        things = Class.new(Grape::API) { get('(:type)') { "type=#{params[:type]}" } }
        Class.new(Grape::API) { mount things => '/things' }
      end

      it 'answers the mount path, with or without the segment' do
        get '/things'
        expect(last_response.body).to eq('type=')

        get '/things/x'
        expect(last_response.body).to eq('type=x')
      end
    end

    context 'when it follows a slash written in the same path' do
      subject do
        Class.new(Grape::API) { get('users/(:id)') { "id=#{params[:id]}" } }
      end

      it 'answers the path before it, with or without the segment' do
        get '/users'
        expect(last_response.body).to eq('id=')

        get '/users/5'
        expect(last_response.body).to eq('id=5')
      end
    end

    context 'when it opens the path of the API' do
      subject do
        Class.new(Grape::API) { get('/(:type)') { "type=#{params[:type]}" } }
      end

      it 'answers the root, with or without the segment' do
        get '/'
        expect(last_response.body).to eq('type=')

        get '/x'
        expect(last_response.body).to eq('type=x')
      end
    end
  end
end
