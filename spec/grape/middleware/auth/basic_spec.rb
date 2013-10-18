require 'spec_helper'

require 'base64'

describe Grape::Middleware::Auth::Basic do
  def app
    Rack::Builder.new do |b|
      b.use Grape::Middleware::Error
      b.use(Grape::Middleware::Auth::Basic) do |u, p|
        u && p && u == p
      end
      b.run lambda { |env| [200, {}, ["Hello there."]] }
    end
  end

  it 'throws a 401 if no auth is given' do
    @proc = lambda { false }
    get '/whatever'
    last_response.status.should == 401
  end

  it 'authenticates if given valid creds' do
    get '/whatever', {}, 'HTTP_AUTHORIZATION' => encode_basic_auth('admin', 'admin')
    last_response.status.should == 200
  end

  it 'throws a 401 is wrong auth is given' do
    get '/whatever', {}, 'HTTP_AUTHORIZATION' => encode_basic_auth('admin', 'wrong')
    last_response.status.should == 401
  end
end
