require 'spec_helper'

class MethodApp < Grape::API
  get '/' do
    'got'
  end
end

describe Grape::Middleware::Method do
  def app
    Rack::Builder.new do |b|
      b.use Grape::Middleware::Error
      b.use Grape::Middleware::Method
      b.run MethodApp
    end
  end

  it 'successful with a supported method' do
    get '/'
    last_response.status == 200
  end

  it 'unsuccessful with a unsupported method' do
    post '/'
    last_response.status == 405
  end

  it 'sets the Allow header when an unsupported method is called' do
    post '/'
    last_response.headers['Allow'].should == 'GET, OPTIONS, HEAD'
  end

  it 'sets the content-type header to text/plain' do
    post '/'
    last_response.headers['Content-type'].should == 'text/plain'
  end
end
