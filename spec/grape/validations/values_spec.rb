require 'spec_helper'

describe Grape::Validations::ValuesValidator do

  module ValidationsSpec
    module ValuesValidatorSpec
      class API < Grape::API
        default_format :json

        params do
          requires :type, values: ['valid-type1', 'valid-type2', 'valid-type3']
        end
        get '/' do
          { type: params[:type] }
        end

        params do
          optional :type, values: ['valid-type1', 'valid-type2', 'valid-type3'], default: 'valid-type2'
        end
        get '/default/valid' do
          { type: params[:type] }
        end

      end
    end
  end

  def app
    ValidationsSpec::ValuesValidatorSpec::API
  end

  it 'allows a valid value for a parameter' do
    get("/", type: 'valid-type1')
    last_response.status.should eq 200
    last_response.body.should eq({ type: "valid-type1" }.to_json)
  end

  it 'does not allow an invalid value for a parameter' do
    get("/", type: 'invalid-type')
    last_response.status.should eq 400
    last_response.body.should eq({ error: "type does not have a valid value" }.to_json)
  end

  it 'allows a valid default value' do
    get("/default/valid")
    last_response.status.should eq 200
    last_response.body.should eq({ type: "valid-type2" }.to_json)
  end

  it 'raises IncompatibleOptionValues on an invalid default value' do
    subject = Class.new(Grape::API)
    expect {
      subject.params { optional :type, values: ['valid-type1', 'valid-type2', 'valid-type3'], default: 'invalid-type' }
    }.to raise_error Grape::Exceptions::IncompatibleOptionValues
  end

  it 'raises IncompatibleOptionValues when type is incompatible with values array' do
    subject = Class.new(Grape::API)
    expect {
      subject.params { optional :type, values: ['valid-type1', 'valid-type2', 'valid-type3'], type: Symbol }
    }.to raise_error Grape::Exceptions::IncompatibleOptionValues
  end

end
