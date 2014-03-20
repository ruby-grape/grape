require 'spec_helper'

describe Grape::Middleware::Auth::OAuth2 do
  class FakeToken
    attr_accessor :token

    def self.verify(token)
      FakeToken.new(token) if !!token && %w(g e).include?(token[0..0])
    end

    def initialize(token)
      @token = token
    end

    def expired?
      @token[0..0] == 'e'
    end

    def permission_for?(env)
      env['PATH_INFO'] == '/forbidden' ? false : true
    end
  end

  def app
    Rack::Builder.app do
      use Grape::Middleware::Auth::OAuth2, token_class: 'FakeToken'
      run lambda { |env| [200, {}, [(env['api.token'].token if env['api.token'])]] }
    end
  end

  shared_examples 'success to authenticate api' do
    let(:access_token) { 'g123' }

    it 'sets status code to 200' do
      last_response.status.should == 200
    end

    it 'sets env["api.token"]' do
      last_response.body.should == access_token
    end
  end

  shared_examples 'fail to authenticate api' do
    let(:error_code) { 401 }
    let(:error_message) { "OAuth realm='OAuth API', error='invalid_grant'" }

    it 'throws an error' do
      @err[:status].should == error_code
    end

    it 'sets the WWW-Authenticate header in the response' do
      @err[:headers]['WWW-Authenticate'].should == error_message
    end
  end

  context 'with the token in the query string' do
    context 'and a valid token' do
      before { get '/awesome?access_token=g123' }

      it_behaves_like 'success to authenticate api'
    end

    context 'and an invalid token' do
      before do
        @err = catch :error do
          get '/awesome?access_token=b123'
        end
      end

      it_behaves_like 'fail to authenticate api'
    end
  end

  context 'with an expired token' do
    before do
      @err = catch :error do
        get '/awesome?access_token=e123'
      end
    end

    it_behaves_like 'fail to authenticate api'
  end

  %w(HTTP_AUTHORIZATION X_HTTP_AUTHORIZATION X-HTTP_AUTHORIZATION REDIRECT_X_HTTP_AUTHORIZATION).each do |head|
    context "with the token in the #{head} header" do
      before do
        get '/awesome', {}, head => 'OAuth g123'
      end

      it_behaves_like 'success to authenticate api'
    end
  end

  context 'with the token in the POST body' do
    before do
      post '/awesome', 'access_token' => 'g123'
    end

    it_behaves_like 'success to authenticate api'
  end

  context 'when accessing something outside its scope' do
    before do
      @err = catch :error do
        get '/forbidden?access_token=g123'
      end
    end

    it_behaves_like 'fail to authenticate api' do
      let(:error_code) { 403 }
      let(:error_message) { "OAuth realm='OAuth API', error='insufficient_scope'" }
    end
  end

  context 'when authorization is not required' do
    def app
      Rack::Builder.app do
        use Grape::Middleware::Auth::OAuth2, token_class: 'FakeToken', required: false
        run lambda { |env| [200, {}, [(env['api.token'].token if env['api.token'])]] }
      end
    end

    context 'with no token' do
      before { post '/awesome' }

      it 'succeeds anyway' do
        last_response.status.should == 200
      end
    end

    context 'with a valid token' do
      before { get '/awesome?access_token=g123' }

      it 'sets env["api.token"]' do
        last_response.body.should == 'g123'
      end
    end
  end

  context 'when root is set' do
    def app
      Rack::Builder.app do
        use Grape::Middleware::Auth::OAuth2, token_class: 'FakeToken', root: '/api'
        run lambda { |env| [200, {}, [(env['api.token'].token if env['api.token'])]] }
      end
    end

    context 'call outside of the root' do
      before do
        get '/awesome'
      end

      it 'succeeds' do
        last_response.status.should == 200
      end
    end

    context 'call inside root' do
      context 'with valid token' do
        before do
          get '/api/awesome?access_token=g123'
        end

        it_behaves_like 'success to authenticate api'
      end

      context 'with an expired token' do
        before do
          @err = catch :error do
            get '/api/awesome?access_token=e123'
          end
        end

        it_behaves_like 'fail to authenticate api'
      end
    end
  end

  context 'when exclude is set to a string' do
    def app
      Rack::Builder.app do
        use Grape::Middleware::Auth::OAuth2, token_class: 'FakeToken', root: '/api', exclude: 'version'
        run lambda { |env| [200, {}, [(env['api.token'].token if env['api.token'])]] }
      end
    end

    context 'calling the excluded url' do
      before do
        get '/api/version'
      end

      it 'succeeds' do
        last_response.status.should == 200
      end
    end
  end

  context 'when exclude is set to an array' do
    def app
      Rack::Builder.app do
        use Grape::Middleware::Auth::OAuth2, token_class: 'FakeToken', root: '/api', exclude: %w(version ping)
        run lambda { |env| [200, {}, [(env['api.token'].token if env['api.token'])]] }
      end
    end

    context 'calling the excluded urls' do
      %w(version ping ping.json).each do |url|
        it 'succeeds' do
          get "/api/#{url}"
          last_response.status.should == 200
        end
      end
    end
  end
end
