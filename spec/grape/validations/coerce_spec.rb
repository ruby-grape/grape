require 'spec_helper'

describe Grape::Validations::CoerceValidator do
  module ValidationsSpec
    module CoerceValidatorSpec
      class User
        include Virtus
        attribute :id, Integer
        attribute :name, String
      end
    
      class API < Grape::API
        default_format :json

        params do
          requires :int, :coerce => Integer
        end
        get '/single' do
        end

        params do
          requires :ids, :type => Array[Integer]
        end
        get '/arr' do
        end

        params do
          requires :user, :type => ValidationsSpec::CoerceValidatorSpec::User
        end
        get '/user' do
        end

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
    end
  end
  
  def app
    ValidationsSpec::CoerceValidatorSpec::API
  end
    
  it "should return an error on malformed input" do
    get '/single', :int => "43a"
    last_response.status.should == 400
    
    get '/single', :int => "43"
    last_response.status.should == 200
  end
  
  it "should return an error on malformed input (array)" do
    get '/arr', :ids => ["1", "2", "az"]
    last_response.status.should == 400
    
    get '/arr', :ids => ["1", "2", "890"]
    last_response.status.should == 200
  end
  
  it "should return an error on malformed input (complex object)" do
    # this request does raise an error inside Virtus
    get '/user', :user => "32"
    last_response.status.should == 400
    
    get '/user', :user => { :id => 32, :name => "Bob"}
    last_response.status.should == 200
  end
  
  it 'should coerce inputs' do
    get('/coerce', :int => "43")
    last_response.status.should == 200
    ret = MultiJson.load(last_response.body)
    ret["int"].should == "Fixnum"
    
    get('/coerce', :int => "40", :arr => ["1","20","3"], :bool => [1, 0])
    # last_response.body.should == ""
    last_response.status.should == 200
    ret = MultiJson.load(last_response.body)
    ret["int"].should == "Fixnum"
    ret["arr"].should == "Fixnum"
    ret["bool"].should == true
  end
  
end
