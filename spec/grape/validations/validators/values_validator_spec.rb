# frozen_string_literal: true

describe Grape::Validations::Validators::ValuesValidator do
  let(:values_model) do
    Class.new do
      class << self
        def values
          @values ||= []
          [default_values + @values].flatten.uniq
        end

        def add_value(value)
          @values ||= []
          @values << value
        end

        def excepts
          @excepts ||= []
          [default_excepts + @excepts].flatten.uniq
        end

        def add_except(except)
          @excepts ||= []
          @excepts << except
        end

        def include?(value)
          values.include?(value)
        end

        def even?(value)
          value.to_i.even?
        end

        private

        def default_values
          %w[valid-type1 valid-type2 valid-type3].freeze
        end

        def default_excepts
          %w[invalid-type1 invalid-type2 invalid-type3].freeze
        end
      end
    end
  end

  let(:app) do
    Class.new(Grape::API) do
      default_format :json

      resources :custom_message do
        params do
          requires :type, values: { value: ValuesModel.values, message: 'value does not include in values' }
        end
        get '/' do
          { type: params[:type] }
        end

        params do
          optional :type, values: { value: -> { ValuesModel.values }, message: 'value does not include in values' }, default: 'valid-type2'
        end
        get '/lambda' do
          { type: params[:type] }
        end
      end

      params do
        requires :type, values: ValuesModel.values
      end
      get '/' do
        { type: params[:type] }
      end

      params do
        requires :type, values: []
      end
      get '/empty'

      params do
        optional :type, values: { value: ValuesModel.values }, default: 'valid-type2'
      end
      get '/default/hash/valid' do
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
        optional :type, type: Integer, values: 1..
      end
      get '/endless' do
        { type: params[:type] }
      end

      params do
        requires :type, values: ->(v) { ValuesModel.include? v }
      end
      get '/lambda_val' do
        { type: params[:type] }
      end

      params do
        requires :number, type: Integer, values: ->(v) { v > 0 }
      end
      get '/lambda_int_val' do
        { number: params[:number] }
      end

      params do
        requires :type, values: -> { [] }
      end
      get '/empty_lambda'

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
        optional :type, type: Grape::API::Boolean, desc: 'A boolean', values: [true]
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
          requires :type, values: %w[a b]
        end
      end
      get '/optional_with_required_values'

      params do
        requires :type, type: Integer, values: 1..5, except_values: [3]
      end
      get '/mixed/value/except' do
        { type: params[:type] }
      end

      params do
        optional :optional, type: Array[String], values: %w[a b c]
      end
      put '/optional_with_array_of_string_values'

      params do
        requires :type, values: ->(v) { ValuesModel.include? v }
      end
      get '/proc' do
        { type: params[:type] }
      end

      params do
        requires :type, values: { value: ->(v) { ValuesModel.include? v }, message: 'failed check' }
      end
      get '/proc/message'

      params do
        requires :number, values: { value: ->(v) { ValuesModel.even? v }, message: 'must be even' }
      end
      get '/proc/custom_message' do
        { message: 'success' }
      end

      params do
        requires :input_one, :input_two, values: { value: ->(v1, v2) { v1 + v2 > 10 } }
      end
      get '/proc/arity2'

      params do
        optional :name, type: String, values: %w[a b], allow_blank: true
      end
      get '/allow_blank'

      params do
        with(type: String) do
          requires :type, values: ValuesModel.values
        end
      end
      get 'values_wrapped_by_with_block'
    end
  end

  before do
    stub_const('ValuesModel', values_model)
  end

  describe '#bad encoding' do
    let(:app) do
      Class.new(Grape::API) do
        default_format :json

        params do
          requires :type, type: String, values: %w[a b]
        end
        get '/bad_encoding'
      end
    end

    context 'when value as bad encoding' do
      it 'does not raise an error' do
        expect { get '/bad_encoding', type: "Hello \x80" }.not_to raise_error
      end
    end
  end

  context 'with a custom validation message' do
    it 'allows a valid value for a parameter' do
      get('/custom_message', type: 'valid-type1')
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq({ type: 'valid-type1' }.to_json)
    end

    it 'does not allow an invalid value for a parameter' do
      get('/custom_message', type: 'invalid-type')
      expect(last_response.status).to eq 400
      expect(last_response.body).to eq({ error: 'type value does not include in values' }.to_json)
    end

    it 'validates against values in a proc' do
      ValuesModel.add_value('valid-type4')

      get('/custom_message/lambda', type: 'valid-type4')
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq({ type: 'valid-type4' }.to_json)
    end

    it 'does not allow an invalid value for a parameter using lambda' do
      get('/custom_message/lambda', type: 'invalid-type')
      expect(last_response.status).to eq 400
      expect(last_response.body).to eq({ error: 'type value does not include in values' }.to_json)
    end
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

  it 'rejects all values if values is an empty array' do
    get('/empty', type: 'invalid-type')
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

    it 'accepts for an optional param with a list of values' do
      put('/optional_with_array_of_string_values', optional: nil)
      expect(last_response.status).to eq 200
    end
  end

  it 'allows a valid default value' do
    get('/default/valid')
    expect(last_response.status).to eq 200
    expect(last_response.body).to eq({ type: 'valid-type2' }.to_json)
  end

  it 'allows a valid default value' do
    get('/default/hash/valid')
    expect(last_response.status).to eq 200
    expect(last_response.body).to eq({ type: 'valid-type2' }.to_json)
  end

  it 'allows a proc for values' do
    get('/lambda', type: 'valid-type1')
    expect(last_response.status).to eq 200
    expect(last_response.body).to eq({ type: 'valid-type1' }.to_json)
  end

  it 'does not validate updated values without proc' do
    app # Instantiate with the existing values.
    ValuesModel.add_value('valid-type4')
    get('/', type: 'valid-type4')
    expect(last_response.status).to eq 400
    expect(last_response.body).to eq({ error: 'type does not have a valid value' }.to_json)
  end

  it 'validates against values in a proc' do
    ValuesModel.add_value('valid-type4')

    get('/lambda', type: 'valid-type4')
    expect(last_response.status).to eq 200
    expect(last_response.body).to eq({ type: 'valid-type4' }.to_json)
  end

  it 'does not allow an invalid value for a parameter using lambda' do
    get('/lambda', type: 'invalid-type')
    expect(last_response.status).to eq 400
    expect(last_response.body).to eq({ error: 'type does not have a valid value' }.to_json)
  end

  it 'validates against values in an endless range' do
    get('/endless', type: 10)
    expect(last_response.status).to eq 200
    expect(last_response.body).to eq({ type: 10 }.to_json)
  end

  it 'does not allow an invalid value for a parameter using an endless range' do
    get('/endless', type: 0)
    expect(last_response.status).to eq 400
    expect(last_response.body).to eq({ error: 'type does not have a valid value' }.to_json)
  end

  it 'does not allow non-numeric string value for int value using lambda' do
    get('/lambda_int_val', number: 'foo')
    expect(last_response.status).to eq 400
    expect(last_response.body).to eq({ error: 'number is invalid, number does not have a valid value' }.to_json)
  end

  it 'does not allow nil for int value using lambda' do
    get('/lambda_int_val', number: nil)
    expect(last_response.status).to eq 400
    expect(last_response.body).to eq({ error: 'number does not have a valid value' }.to_json)
  end

  it 'allows numeric string for int value using lambda' do
    get('/lambda_int_val', number: '3')
    expect(last_response.status).to eq 200
    expect(last_response.body).to eq({ number: 3 }.to_json)
  end

  it 'allows value using lambda' do
    get('/lambda_val', type: 'valid-type1')
    expect(last_response.status).to eq 200
    expect(last_response.body).to eq({ type: 'valid-type1' }.to_json)
  end

  it 'does not allow invalid value using lambda' do
    get('/lambda_val', type: 'invalid-type')
    expect(last_response.status).to eq 400
    expect(last_response.body).to eq({ error: 'type does not have a valid value' }.to_json)
  end

  it 'validates against an empty array in a proc' do
    get('/empty_lambda', type: 'any')
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
      subject.params { optional :type, values: %w[valid-type1 valid-type2 valid-type3], default: "#{ValuesModel.values.sample}_invalid" }
    end.to raise_error Grape::Exceptions::IncompatibleOptionValues
  end

  it 'raises IncompatibleOptionValues on an invalid default value' do
    subject = Class.new(Grape::API)
    expect do
      subject.params { optional :type, values: %w[valid-type1 valid-type2 valid-type3], default: 'invalid-type' }
    end.to raise_error Grape::Exceptions::IncompatibleOptionValues
  end

  it 'raises IncompatibleOptionValues when type is incompatible with values array' do
    subject = Class.new(Grape::API)
    expect do
      subject.params { optional :type, values: %w[valid-type1 valid-type2 valid-type3], type: Symbol }
    end.to raise_error Grape::Exceptions::IncompatibleOptionValues
  end

  context 'boolean values' do
    it 'allows a value from the list' do
      get('/values/optional_boolean', type: true)

      expect(last_response.status).to eq 200
      expect(last_response.body).to eq({ type: true }.to_json)
    end

    it 'rejects a value which is not in the list' do
      get('/values/optional_boolean', type: false)

      expect(last_response.body).to eq({ error: 'type does not have a valid value' }.to_json)
    end
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

  it 'raises IncompatibleOptionValues when except contains a value that is not a kind of the type' do
    subject = Class.new(Grape::API)
    expect do
      subject.params { requires :type, except_values: [10.5, 11], type: Integer }
    end.to raise_error Grape::Exceptions::IncompatibleOptionValues
  end

  it 'allows a blank value when the allow_blank option is true' do
    get 'allow_blank', name: nil
    expect(last_response.status).to eq(200)

    get 'allow_blank', name: ''
    expect(last_response.status).to eq(200)
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

  context 'with mixed values and excepts' do
    it 'allows value, but not in except' do
      get '/mixed/value/except', type: 2
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq({ type: 2 }.to_json)
    end

    it 'rejects except' do
      get '/mixed/value/except', type: 3
      expect(last_response.status).to eq 400
      expect(last_response.body).to eq({ error: 'type has a value not allowed' }.to_json)
    end

    it 'rejects outside except and outside value' do
      get '/mixed/value/except', type: 10
      expect(last_response.status).to eq 400
      expect(last_response.body).to eq({ error: 'type does not have a valid value' }.to_json)
    end
  end

  context 'custom validation using proc' do
    it 'accepts a single valid value' do
      get '/proc', type: 'valid-type1'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq({ type: 'valid-type1' }.to_json)
    end

    it 'accepts multiple valid values' do
      get '/proc', type: %w[valid-type1 valid-type3]
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq({ type: %w[valid-type1 valid-type3] }.to_json)
    end

    it 'rejects a single invalid value' do
      get '/proc', type: 'invalid-type1'
      expect(last_response.status).to eq 400
      expect(last_response.body).to eq({ error: 'type does not have a valid value' }.to_json)
    end

    it 'rejects an invalid value among valid ones' do
      get '/proc', type: %w[valid-type1 invalid-type1 valid-type3]
      expect(last_response.status).to eq 400
      expect(last_response.body).to eq({ error: 'type does not have a valid value' }.to_json)
    end

    it 'uses supplied message' do
      get '/proc/message', type: 'invalid-type1'
      expect(last_response.status).to eq 400
      expect(last_response.body).to eq({ error: 'type failed check' }.to_json)
    end

    context 'when proc has an arity of 1' do
      it 'accepts a valid value' do
        get '/proc/custom_message', number: 4
        expect(last_response.status).to eq 200
        expect(last_response.body).to eq({ message: 'success' }.to_json)
      end

      it 'rejects an invalid value' do
        get '/proc/custom_message', number: 5
        expect(last_response.status).to eq 400
        expect(last_response.body).to eq({ error: 'number must be even' }.to_json)
      end
    end

    context 'when arity is > 1' do
      it 'returns an error status code' do
        get '/proc/arity2', input_one: 2, input_two: 3
        expect(last_response.status).to eq 400
      end
    end
  end

  context 'when wrapped by with block' do
    it 'rejects an invalid value' do
      get 'values_wrapped_by_with_block'

      expect(last_response.status).to eq 400
      expect(last_response.body).to eq({ error: 'type is missing, type does not have a valid value' }.to_json)
    end
  end
end
