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

        params do
          optional :random, default: -> { Random.rand }
          optional :not_random, default: Random.rand
        end
        get '/numbers' do
          { random_number: params[:random], non_random_number: params[:non_random_number] }
        end

        params do
          # NOTE: The :foo parameter could be made required with json body
          # params, and then an empty hash would be valid. With query parameters
          # it must be optional if it isn't provided at all, as otherwise
          # the validaton for the Hash itself fails because there is no such
          # thing as an empty hash.
          optional :foo, type: Hash do
            optional :bar, default: 'foo-bar'
          end
        end
        get '/group' do
          { foo_bar: params[:foo][:bar] }
        end

        params do
          optional :array, type: Array do
            requires :name
            optional :with_default, default: 'default'
          end
        end
        get '/array' do
          { array: params[:array] }
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

  it 'sets lambda based defaults at the time of call' do
    get("/numbers")
    last_response.status.should == 200
    before = JSON.parse(last_response.body)
    get("/numbers")
    last_response.status.should == 200
    after = JSON.parse(last_response.body)

    before['non_random_number'].should == after['non_random_number']
    before['random_number'].should_not == after['random_number']
  end

  it 'set default values for optional grouped params' do
    get('/group')
    last_response.status.should == 200
    last_response.body.should == { foo_bar: 'foo-bar' }.to_json
  end

  it 'sets default values for grouped arrays' do
    get('/array?array[][name]=name&array[][name]=name2&array[][with_default]=bar2')
    last_response.status.should == 200
    last_response.body.should == { array: [{ name: "name", with_default: "default" }, { name: "name2", with_default: "bar2" }] }.to_json
  end

end
