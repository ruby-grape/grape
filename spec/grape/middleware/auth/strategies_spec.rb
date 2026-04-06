# frozen_string_literal: true

describe Grape::Middleware::Auth::Strategies do
  describe 'Basic Auth' do
    let(:app) do
      proc = ->(u, p) { u && p && u == p }
      Rack::Builder.app do
        use Grape::Middleware::Error
        use(Grape::Middleware::Auth::Base, type: :http_basic, proc:)
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

  describe 'Custom Auth strategy inheriting from Grape::Middleware::Auth::Base' do
    let(:custom_auth_middleware) do
      Class.new(Grape::Middleware::Auth::Base) do
        def call(env)
          if env['HTTP_AUTHORIZATION'] == 'valid-token'
            @app.call(env)
          else
            [401, {}, ['Unauthorized']]
          end
        end
      end
    end

    let(:app) do
      middleware = custom_auth_middleware

      Class.new(Grape::API) do
        Grape::Middleware::Auth::Strategies.add(:custom_token, middleware)
        auth(:custom_token) {}
        get('/whatever') { 'Hello there.' }
      end
    end

    it 'allows access with valid token' do
      get '/whatever', {}, 'HTTP_AUTHORIZATION' => 'valid-token'
      expect(last_response).to be_successful
      expect(last_response.body).to eq('Hello there.')
    end

    it 'denies access without valid token' do
      get '/whatever'
      expect(last_response).to be_unauthorized
    end
  end
end
