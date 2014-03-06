require 'spec_helper'

describe Grape::Validations::ValuesValidator do

  class ValuesModel
    DEFAULT_VALUES = ['valid-type1', 'valid-type2', 'valid-type3']
    class << self
      def values
        @values ||= []
        [DEFAULT_VALUES + @values].flatten.uniq
      end

      def add_value(value)
        @values ||= []
        @values << value
      end
    end
  end

  module ValidationsSpec
    module ValuesValidatorSpec
      class API < Grape::API
        default_format :json

        params do
          requires :type, values: ValuesModel.values
        end
        get '/' do
          { type: params[:type] }
        end

        params do
          optional :type, values: ValuesModel.values, default: 'valid-type2'
        end
        get '/default/valid' do
          { type: params[:type] }
        end

        params do
          optional :type, values: -> { ValuesModel.values }, default: 'valid-type2'
        end
        get '/lambda' do
          { type: params[:type] }
        end

        params do
          requires :type, type: Integer, desc: "An integer", values: [10, 11], default: 10
        end
        get '/values/coercion' do
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

  it 'does not allow nil value for a parameter' do
    get("/", type: nil)
    last_response.status.should eq 400
    last_response.body.should eq({ error: "type does not have a valid value" }.to_json)
  end

  it 'allows a valid default value' do
    get("/default/valid")
    last_response.status.should eq 200
    last_response.body.should eq({ type: "valid-type2" }.to_json)
  end

  it 'allows a proc for values' do
    get('/lambda', type: 'valid-type1')
    last_response.status.should eq 200
    last_response.body.should eq({ type: "valid-type1" }.to_json)
  end

  it 'does not validate updated values without proc' do
    ValuesModel.add_value('valid-type4')

    get('/', type: 'valid-type4')
    last_response.status.should eq 400
    last_response.body.should eq({ error: "type does not have a valid value" }.to_json)
  end

  it 'validates against values in a proc' do
    ValuesModel.add_value('valid-type4')

    get('/lambda', type: 'valid-type4')
    last_response.status.should eq 200
    last_response.body.should eq({ type: "valid-type4" }.to_json)
  end

  it 'does not allow an invalid value for a parameter using lambda' do
    get("/lambda", type: 'invalid-type')
    last_response.status.should eq 400
    last_response.body.should eq({ error: "type does not have a valid value" }.to_json)
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

  it 'allows values to be a kind of the coerced type not just an instance of it' do
    get("/values/coercion", type: 10)
    last_response.status.should eq 200
    last_response.body.should eq({ type: 10 }.to_json)
  end

  it 'raises IncompatibleOptionValues when values contains a value that is not a kind of the type' do
    subject = Class.new(Grape::API)
    expect {
      subject.params { requires :type, values: [10.5, 11], type: Integer }
    }.to raise_error Grape::Exceptions::IncompatibleOptionValues
  end
end
