# frozen_string_literal: true

describe Grape::Middleware::Auth::Base do
  subject do
    Class.new(Grape::API) do
      http_basic realm: 'my_realm' do |user, password|
        user && password && user == password
      end
      get '/authorized' do
        'DONE'
      end
    end
  end

  let(:app) { subject }

  it 'authenticates if given valid creds' do
    get '/authorized', {}, 'HTTP_AUTHORIZATION' => encode_basic_auth('admin', 'admin')
    expect(last_response).to be_successful
    expect(last_response.body).to eq('DONE')
  end

  it 'throws a 401 is wrong auth is given' do
    get '/authorized', {}, 'HTTP_AUTHORIZATION' => encode_basic_auth('admin', 'wrong')
    expect(last_response).to be_unauthorized
  end

  describe '#call!' do
    subject(:middleware) { described_class.new(->(_env) { [200, {}, ['DONE']] }, type: :http_basic, realm: 'my_realm', proc: ->(user, password) { user == password }) }

    let(:endpoint) { Spec::Support::EndpointFaker::FakerAPI.endpoints.first }
    let(:env) { Rack::MockRequest.env_for('/', 'HTTP_AUTHORIZATION' => encode_basic_auth('admin', 'admin')).merge(Grape::Env::API_ENDPOINT => endpoint) }

    it 'answers the request and keeps its endpoint within reach, as Base#call! does' do
      status, = middleware.call!(env)

      expect([status, middleware.context]).to eq([200, endpoint])
    end
  end
end
