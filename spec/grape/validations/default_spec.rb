require 'spec_helper'

describe Grape::Validations::DefaultValidator do

  module ValidationsSpec
    module DefaultValidatorSpec
      class API < Grape::API
        default_format :json

        params do
          optional :id
          optional :type, default: 'default-type'
        end
        get '/' do
          { id: params[:id], type: params[:type] }
        end

        params do
          optional :type1, default: 'default-type1'
          optional :type2, default: 'default-type2'
        end
        get '/user' do
          { type1: params[:type1], type2: params[:type2] }
        end

        params do
          requires :id
          optional :type1, default: 'default-type1'
          optional :type2, default: 'default-type2'
        end

        get '/message' do
          { id: params[:id], type1: params[:type1], type2: params[:type2] }
        end
      end
    end
  end

  def app
    ValidationsSpec::DefaultValidatorSpec::API
  end

  it 'set default value for optional param' do
    get("/")
    last_response.status.should == 200
    last_response.body.should == { id: nil, type: 'default-type' }.to_json
  end

  it 'set default values for optional params' do
    get("/user")
    last_response.status.should == 200
    last_response.body.should == { type1: 'default-type1', type2: 'default-type2' }.to_json
  end

  it 'set default values for missing params in the request' do
    get("/user?type2=value2")
    last_response.status.should == 200
    last_response.body.should == { type1: 'default-type1', type2: 'value2' }.to_json
  end

  it 'set default values for optional params and allow to use required fields in the same time' do
    get("/message?id=1")
    last_response.status.should == 200
    last_response.body.should == { id: '1', type1: 'default-type1', type2: 'default-type2' }.to_json
  end
end
