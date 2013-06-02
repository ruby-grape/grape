require 'spec_helper'

class OptionsApp < Grape::API
  resources :options_spec do
    get '/' do
      'got'
    end

    put '/' do
      ''
    end

    post '/' do
      ''
    end
  end
end

class OptionsWithoutHeadApp < Grape::API
  do_not_route_head!

  get '/' do
    'got'
  end
end

describe Grape::Middleware::Options do
  def app
    Rack::Builder.new do |b|
      b.use Grape::Middleware::Error
      b.use Grape::Middleware::Options
      b.run OptionsApp
    end
  end

  it 'returns a header with the allowed methods for a given route' do
    options '/options_spec/'
    last_response.headers['Allow'].should == 'GET, PUT, POST, OPTIONS, HEAD'
  end

  it 'returns a 204 status code' do
    options '/options_spec/'
    last_response.status.should == 204
  end

  it 'returns the apps get method when not an options request' do
    get '/options_spec/'
    last_response.body.should == 'got'
  end

  describe OptionsWithoutHeadApp do
    def app
      Rack::Builder.new do |b|
        b.use Grape::Middleware::Error
        b.use Grape::Middleware::Options
        b.run OptionsWithoutHeadApp
      end
    end

    it 'should not return HEAD as an allowed method' do
      options '/'
      last_response.headers['Allow'].should == 'GET, OPTIONS'
      last_response.headers['Allow'].should_not include 'HEAD'
    end
  end
end
