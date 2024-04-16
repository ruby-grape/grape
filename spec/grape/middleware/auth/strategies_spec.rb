# frozen_string_literal: true

describe Grape::Middleware::Auth::Strategies do
  describe 'Basic Auth' do
    let(:app) do
      proc = ->(u, p) { u && p && u == p }
      Rack::Builder.new do |b|
        b.use Grape::Middleware::Error
        b.use(Grape::Middleware::Auth::Base, type: :http_basic, proc: proc)
        b.run ->(_env) { [200, {}, ['Hello there.']] }
      end
    end

    it 'throws a 401 if no auth is given' do
      get '/whatever'
      expect(last_response).to be_unauthorized
    end

    it 'authenticates if given valid creds' do
      get '/whatever', {}, 'HTTP_AUTHORIZATION' => encode_basic_auth('admin', 'admin')
      expect(last_response).to be_successful
    end

    it 'throws a 401 is wrong auth is given' do
      get '/whatever', {}, 'HTTP_AUTHORIZATION' => encode_basic_auth('admin', 'wrong')
      expect(last_response).to be_unauthorized
    end
  end
end
