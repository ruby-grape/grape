require 'spec_helper'

describe Grape::Validations::ValuesValidator do
  module ValidationsSpec
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
          optional :type, values: ValuesModel.values, default: -> { ValuesModel.values.sample }
        end
        get '/default_lambda' do
          { type: params[:type] }
        end

        params do
          optional :type, values: -> { ValuesModel.values }, default: -> { ValuesModel.values.sample }
        end
        get '/default_and_values_lambda' do
          { type: params[:type] }
        end

        params do
          optional :type, type: Boolean, desc: 'A boolean', values: [true]
        end
        get '/values/optional_boolean' do
          { type: params[:type] }
        end

        params do
          requires :type, type: Integer, desc: 'An integer', values: [10, 11], default: 10
        end
        get '/values/coercion' do
          { type: params[:type] }
        end

        params do
          requires :type, type: Array[Integer], desc: 'An integer', values: [10, 11], default: 10
        end
        get '/values/array_coercion' do
          { type: params[:type] }
        end

        params do
          optional :optional, type: Array do
            requires :type, values: %w(a b)
          end
        end
        get '/optional_with_required_values'
      end
    end
  end

  def app
    ValidationsSpec::ValuesValidatorSpec::API
  end

  it 'allows a valid value for a parameter' do
    get('/', type: 'valid-type1')
    expect(last_response.status).to eq 200
    expect(last_response.body).to eq({ type: 'valid-type1' }.to_json)
  end

  it 'does not allow an invalid value for a parameter' do
    get('/', type: 'invalid-type')
    expect(last_response.status).to eq 400
    expect(last_response.body).to eq({ error: 'type does not have a valid value' }.to_json)
  end

  context 'nil value for a parameter' do
    it 'does not allow for root params scope' do
      get('/', type: nil)
      expect(last_response.status).to eq 400
      expect(last_response.body).to eq({ error: 'type does not have a valid value' }.to_json)
    end

    it 'allows for a required param in child scope' do
      get('/optional_with_required_values')
      expect(last_response.status).to eq 200
    end
  end

  it 'allows a valid default value' do
    get('/default/valid')
    expect(last_response.status).to eq 200
    expect(last_response.body).to eq({ type: 'valid-type2' }.to_json)
  end

  it 'allows a proc for values' do
    get('/lambda', type: 'valid-type1')
    expect(last_response.status).to eq 200
    expect(last_response.body).to eq({ type: 'valid-type1' }.to_json)
  end

  it 'does not validate updated values without proc' do
    ValidationsSpec::ValuesModel.add_value('valid-type4')

    get('/', type: 'valid-type4')
    expect(last_response.status).to eq 400
    expect(last_response.body).to eq({ error: 'type does not have a valid value' }.to_json)
  end

  it 'validates against values in a proc' do
    ValidationsSpec::ValuesModel.add_value('valid-type4')

    get('/lambda', type: 'valid-type4')
    expect(last_response.status).to eq 200
    expect(last_response.body).to eq({ type: 'valid-type4' }.to_json)
  end

  it 'does not allow an invalid value for a parameter using lambda' do
    get('/lambda', type: 'invalid-type')
    expect(last_response.status).to eq 400
    expect(last_response.body).to eq({ error: 'type does not have a valid value' }.to_json)
  end

  it 'validates default value from proc' do
    get('/default_lambda')
    expect(last_response.status).to eq 200
  end

  it 'validates default value from proc against values in a proc' do
    get('/default_and_values_lambda')
    expect(last_response.status).to eq 200
  end

  it 'raises IncompatibleOptionValues on an invalid default value from proc' do
    subject = Class.new(Grape::API)
    expect do
      subject.params { optional :type, values: ['valid-type1', 'valid-type2', 'valid-type3'], default: ValidationsSpec::ValuesModel.values.sample + '_invalid' }
    end.to raise_error Grape::Exceptions::IncompatibleOptionValues
  end

  it 'raises IncompatibleOptionValues on an invalid default value' do
    subject = Class.new(Grape::API)
    expect do
      subject.params { optional :type, values: ['valid-type1', 'valid-type2', 'valid-type3'], default: 'invalid-type' }
    end.to raise_error Grape::Exceptions::IncompatibleOptionValues
  end

  it 'raises IncompatibleOptionValues when type is incompatible with values array' do
    subject = Class.new(Grape::API)
    expect do
      subject.params { optional :type, values: ['valid-type1', 'valid-type2', 'valid-type3'], type: Symbol }
    end.to raise_error Grape::Exceptions::IncompatibleOptionValues
  end

  it 'allows values to be true or false when setting the type to boolean' do
    get('/values/optional_boolean', type: true)
    expect(last_response.status).to eq 200
    expect(last_response.body).to eq({ type: true }.to_json)
  end
  it 'allows values to be a kind of the coerced type not just an instance of it' do
    get('/values/coercion', type: 10)
    expect(last_response.status).to eq 200
    expect(last_response.body).to eq({ type: 10 }.to_json)
  end

  it 'allows values to be a kind of the coerced type in an array' do
    get('/values/array_coercion', type: [10])
    expect(last_response.status).to eq 200
    expect(last_response.body).to eq({ type: [10] }.to_json)
  end

  it 'raises IncompatibleOptionValues when values contains a value that is not a kind of the type' do
    subject = Class.new(Grape::API)
    expect do
      subject.params { requires :type, values: [10.5, 11], type: Integer }
    end.to raise_error Grape::Exceptions::IncompatibleOptionValues
  end

  context 'with a lambda values' do
    subject do
      Class.new(Grape::API) do
        params do
          optional :type, type: String, values: -> { [SecureRandom.uuid] }, default: -> { SecureRandom.uuid }
        end
        get '/random_values'
      end
    end

    def app
      subject
    end

    before do
      expect(SecureRandom).to receive(:uuid).and_return('foo').once
    end

    it 'only evaluates values dynamically with each request' do
      get '/random_values', type: 'foo'
      expect(last_response.status).to eq 200
    end

    it 'chooses default' do
      get '/random_values'
      expect(last_response.status).to eq 200
    end
  end

  context 'with a range of values' do
    subject(:app) do
      Class.new(Grape::API) do
        params do
          optional :value, type: Float, values: 0.0..10.0
        end
        get '/value' do
          { value: params[:value] }.to_json
        end

        params do
          optional :values, type: Array[Float], values: 0.0..10.0
        end
        get '/values' do
          { values: params[:values] }.to_json
        end
      end
    end

    it 'allows a single value inside of the range' do
      get('/value', value: 5.2)
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq({ value: 5.2 }.to_json)
    end

    it 'allows an array of values inside of the range' do
      get('/values', values: [8.6, 7.5, 3, 0.9])
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq({ values: [8.6, 7.5, 3.0, 0.9] }.to_json)
    end

    it 'rejects a single value outside the range' do
      get('/value', value: 'a')
      expect(last_response.status).to eq 400
      expect(last_response.body).to eq('value is invalid, value does not have a valid value')
    end

    it 'rejects an array of values if any of them are outside the range' do
      get('/values', values: [8.6, 75, 3, 0.9])
      expect(last_response.status).to eq 400
      expect(last_response.body).to eq('values does not have a valid value')
    end
  end
end
