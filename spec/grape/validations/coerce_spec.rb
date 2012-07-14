require 'spec_helper'

class CoerceAPI < Grape::API
  default_format :json
  
  params do
    requires :int, :coerce => Integer
    optional :arr, :coerce => Array[Integer]
    optional :bool, :coerce => Array[Boolean]
  end
  get '/coerce' do
    {
      :int    => params[:int].class,
      :arr    => params[:arr] ? params[:arr][0].class : nil,
      :bool   => params[:bool] ? (params[:bool][0] == true) && (params[:bool][1] == false) : nil
    }
  end
end

describe Grape::Validations::CoerceValidator do
  def app; @app; end
  
  before do
    @app = CoerceAPI
  end
  
  # TOOD: Later when virtus can tell us that an input IS invalid
  # it "should return an error on malformed input" do
  #   get '/coerce', :int => "43a"
  #   last_response.status.should == 400
  # end
  
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
