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

  context 'with the token in the query string' do
    context 'and a valid token' do
      before { get '/awesome?access_token=g123' }

      it 'sets env["api.token"]' do
        last_response.body.should == 'g123'
      end
    end

    context 'and an invalid token' do
      before do
        @err = catch :error do
          get '/awesome?access_token=b123'
        end
      end

      it 'throws an error' do
        @err[:status].should == 401
      end

      it 'sets the WWW-Authenticate header in the response' do
        @err[:headers]['WWW-Authenticate'].should == "OAuth realm='OAuth API', error='invalid_grant'"
      end
    end
  end

  context 'with an expired token' do
    before do
      @err = catch :error do
        get '/awesome?access_token=e123'
      end
    end

    it 'throws an error' do
      @err[:status].should == 401
    end

    it 'sets the WWW-Authenticate header in the response to error' do
      @err[:headers]['WWW-Authenticate'].should == "OAuth realm='OAuth API', error='invalid_grant'"
    end
  end

  %w(HTTP_AUTHORIZATION X_HTTP_AUTHORIZATION X-HTTP_AUTHORIZATION REDIRECT_X_HTTP_AUTHORIZATION).each do |head|
    context "with the token in the #{head} header" do
      before do
        get '/awesome', {}, head => 'OAuth g123'
      end

      it 'sets env["api.token"]' do
        last_response.body.should == 'g123'
      end
    end
  end

  context 'with the token in the POST body' do
    before do
      post '/awesome', 'access_token' => 'g123'
    end

    it 'sets env["api.token"]' do
      last_response.body.should == 'g123'
    end
  end

  context 'when accessing something outside its scope' do
    before do
      @err = catch :error do
        get '/forbidden?access_token=g123'
      end
    end

    it 'throws an error' do
      @err[:status].should == 403
    end

    it 'sets the WWW-Authenticate header in the response to error' do
      @err[:headers]['WWW-Authenticate'].should == "OAuth realm='OAuth API', error='insufficient_scope'"
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
end
