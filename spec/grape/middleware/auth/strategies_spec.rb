# frozen_string_literal: true

describe Grape::Middleware::Auth::Strategies do
  describe 'Basic Auth' do
    let(:app) do
      proc = ->(u, p) { u && p && u == p }
      Rack::Builder.app do
        use Grape::Middleware::Error
        use(Grape::Middleware::Auth::Base, type: :http_basic, proc: proc)
        run ->(_env) { [200, {}, ['Hello there.']] }
      end
    end

    it 'throws a 401 if no auth is given' do
      get '/whatever'
      expect(last_response).to be_unauthorized
    end

    it 'authenticates if given valid creds' do
      get '/whatever', {}, 'HTTP_AUTHORIZATION' => encode_basic_auth('admin', 'admin')
      expect(last_response).to be_successful
      expect(last_response.body).to eq('Hello there.')
    end

    it 'throws a 401 is wrong auth is given' do
      get '/whatever', {}, 'HTTP_AUTHORIZATION' => encode_basic_auth('admin', 'wrong')
      expect(last_response).to be_unauthorized
    end
  end

  describe 'Unknown Auth' do
    context 'when type is not register' do
      let(:app) do
        Class.new(Grape::API) do
          use Grape::Middleware::Auth::Base, type: :unknown
          get('/whatever') { 'Hello there.' }
        end
      end

      it 'throws a 401' do
        expect { get '/whatever' }.to raise_error(Grape::Exceptions::UnknownAuthStrategy, 'unknown auth strategy: unknown')
      end
    end
  end
end
