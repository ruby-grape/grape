require 'spec_helper'

describe Grape::Endpoint do
  subject { Class.new(Grape::API) }
  before { subject.default_format :txt }
  def app; subject end

  describe '#template' do
    it 'should be callable from within a block' do
      subject.get('/home') do
        template 'foo.bar'
        "Hello"
      end

      get '/home', {}, { 'api.tilt.root' => '/path/to/root' }
      last_response.status.should == 200
      last_response.body.should == "<em>Hello</em>"
    end
  end

  describe '#status' do
    it 'should be callable from within a block' do
      subject.get('/home') do
        status 206
        "Hello"
      end
      
      get '/home'
      last_response.status.should == 206
      last_response.body.should == "Hello"
    end
  end
  
  describe '#header' do
    it 'should be callable from within a block' do
      subject.get('/hey') do
        header 'X-Awesome', 'true'
        "Awesome"
      end
      
      get '/hey'
      last_response.headers['X-Awesome'].should == 'true'
    end
  end
  
  describe '#params' do
    it 'should be available to the caller' do
      subject.get('/hey') do
        params[:howdy]
      end
      
      get '/hey?howdy=hey'
      last_response.body.should == 'hey'
    end
    
    it 'should parse from path segments' do
      subject.get('/hey/:id') do
        params[:id]
      end
      
      get '/hey/12'
      last_response.body.should == '12'
    end
  end
  
  describe '#error!' do
    it 'should accept a message' do
      subject.get('/hey') do
        error! "This is not valid."
        "This is valid."
      end
      
      get '/hey'
      last_response.status.should == 403
      last_response.body.should == "This is not valid."
    end
    
    it 'should accept a code' do
      subject.get('/hey') do
        error! "Unauthorized.", 401
      end
      
      get '/hey'
      last_response.status.should == 401
      last_response.body.should == "Unauthorized."
    end

    it 'should accept an object and render it in format' do
      subject.get '/hey' do
        error!({'dude' => 'rad'}, 403)
      end

      get '/hey.json'
      last_response.status.should == 403
      last_response.body.should == '{"dude":"rad"}'
    end
  end
  
  it 'should not persist params between calls' do
    subject.post('/new') do
      params[:text]
    end
    
    post '/new', :text => 'abc'
    last_response.body.should == 'abc'
    
    post '/new', :text => 'def'
    last_response.body.should == 'def'
  end
  
  it 'should reset all instance variables (except block) between calls' do
    subject.helpers do
      def memoized
        @memoized ||= params[:howdy]
      end
    end
    
    subject.get('/hello') do
      memoized
    end
    
    get '/hello?howdy=hey'
    last_response.body.should == 'hey'
    get '/hello?howdy=yo'
    last_response.body.should == 'yo'
  end
end
