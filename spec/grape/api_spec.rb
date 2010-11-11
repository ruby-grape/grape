require 'spec_helper'

describe Grape::API do
  subject { Class.new(Grape::API) }
  before { subject.default_format :txt }
  
  def app; subject end
  
  describe '.prefix' do
    it 'should route through with the prefix' do
      subject.prefix 'awesome/sauce'
      subject.get :hello do
        "Hello there."
      end
    
      get 'awesome/sauce/hello'
      last_response.body.should == "Hello there."
      
      get '/hello'
      last_response.status.should == 404
    end
  end
  
  describe '.version' do
    it 'should set the API version' do
      subject.version 'v1'
      subject.get :hello do
        "Version: #{request.env['api.version']}"
      end
      
      get '/v1/hello'
      last_response.body.should == "Version: v1"
    end
    
    it 'should add the prefix before the API version' do
      subject.prefix 'api'
      subject.version 'v1'
      subject.get :hello do
        "Version: #{request.env['api.version']}"
      end
      
      get '/api/v1/hello'
      last_response.body.should == "Version: v1"
    end
  end
end