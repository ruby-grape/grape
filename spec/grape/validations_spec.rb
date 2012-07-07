require 'spec_helper'

describe Grape::Validations do
  def app; @app; end
  
  before do
    @app = Class.new(Grape::API) do
      default_format :json
      
      requires :id, :regexp => /^[0-9]+$/
      post do
        {:ret => params[:id]}
      end
      
      requires :name, :company
      optional :a_number, :regexp => /^[0-9]+$/
      get do
        "Hello"
      end
      
      requires :int, :coerce => Integer
      optional :arr, :coerce => Array[Integer]
      optional :bool, :coerce => Array[Boolean]
      get '/coerce' do
        {
          :int    => params[:int].class,
          :arr    => params[:arr] ? params[:arr][0].class : nil,
          :bool   => params[:bool] ? (params[:bool][0] == true) && (params[:bool][1] == false) : nil
        }
      end
      
    end
    
  end
  
  it 'validates id' do
    post('/')
    last_response.status.should == 400
    last_response.body.should == "missing parameter: id"
    
    post('/', {}, 'rack.input' => StringIO.new('{"id" : "a56b"}'))
    last_response.body.should == 'invalid parameter: id'
    last_response.status.should == 400
    
    post('/', {}, 'rack.input' => StringIO.new('{"id" : 56}'))
    last_response.body.should == '{"ret":56}'
    last_response.status.should == 201
  end
  
  it 'validates name, company' do
    get('/')
    last_response.status.should == 400
    last_response.body.should == "missing parameter: name"
    
    get('/', :name => "Bob")
    last_response.status.should == 400
    last_response.body.should == "missing parameter: company"
    
    get('/', :name => "Bob", :company => "TestCorp")
    last_response.status.should == 200
    last_response.body.should == "Hello"
  end
  
  it 'validates optional parameter if present' do
    get('/', :name => "Bob", :company => "TestCorp", :a_number => "string")
    last_response.status.should == 400
    last_response.body.should == "invalid parameter: a_number"
    
    get('/', :name => "Bob", :company => "TestCorp", :a_number => 45)
    last_response.status.should == 200
    last_response.body.should == "Hello"
  end
  
  it 'should coerce inputs' do
    get('/coerce', :int => "43")
    last_response.status.should == 200
    ret = MultiJson.load(last_response.body)
    ret["int"].should == "Fixnum"
    
    get('/coerce', :int => "40", :arr => ["1","20","3"], :bool => [1, 0])
    last_response.status.should == 200
    ret = MultiJson.load(last_response.body)
    ret["int"].should == "Fixnum"
    ret["arr"].should == "Fixnum"
    ret["bool"].should == true
  end

end
