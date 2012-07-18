require 'spec_helper'

describe Grape::Validations do 
  module ValidationsSpec
    class API < Grape::API
      default_format :json
      
      params do
        requires :name, :company
        optional :a_number, :regexp => /^[0-9]+$/
      end
      
      get do
        "Hello"
      end
    end
  end
  
  def app
    ValidationsSpec::API 
  end

  it 'validates optional parameter if present' do
    get('/', :name => "Bob", :company => "TestCorp", :a_number => "string")
    last_response.status.should == 400
    last_response.body.should == "invalid parameter: a_number"
    
    get('/', :name => "Bob", :company => "TestCorp", :a_number => 45)
    last_response.status.should == 200
    last_response.body.should == "Hello"
  end
  
end
