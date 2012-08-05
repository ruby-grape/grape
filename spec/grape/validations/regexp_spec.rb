require 'spec_helper'

describe Grape::Validations::RegexpValidator do
  module ValidationsSpec
    module RegexpValidatorSpec
      class API < Grape::API
        default_format :json
        
        params do
          requires :name, :regexp => /^[a-z]+$/
        end
        get do
          
        end
        
        params do
          requires 'user.id', :regexp => /^[Aa]+$/
        end
        get('/nested'){}
        
      end
    end
  end
  
  def app
    ValidationsSpec::RegexpValidatorSpec::API
  end
  
  it 'should refuse invalid input' do
    get '/', :name => "invalid name"
    last_response.status.should == 400
  end
  
  it 'should accept valid input' do
    get '/', :name => "bob"
    last_response.status.should == 200
  end
  
  it 'should works with nested attributes' do
    get '/nested'
    last_response.status.should == 400
    last_response.body.should == "missing parameter: user.id"
    
    get '/nested', :user => {:id => "tt"}
    last_response.status.should == 400
    last_response.body.should == "invalid parameter: user.id"

    get '/nested', :user => {:id => "aAAAaaa"}
    last_response.status.should == 200
  end
  
end
