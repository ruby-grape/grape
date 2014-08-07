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

        params do
          optional :optional do
            requires :type, values: ["a", "b"]
          end
        end
        get '/optional_with_required_values'

        ################# New stuff from Jack ###############################
        params do
          optional :type, type: Integer
        end
        get '/values/optional_does_not_allow_nil_for_integer' do
          { type: params[:type] }
        end

        params do
          requires :type, type: Integer
        end
        get '/values/required_does_not_allow_nil_for_integer' do
          { type: params[:type] }
        end

        ####################################################################

      end
    end
  end

  def app
    ValidationsSpec::ValuesValidatorSpec::API
  end

  it 'allows a valid value for a parameter' do
    get("/", type: 'valid-type1')
    expect(last_response.status).to eq 200
    expect(last_response.body).to eq({ type: "valid-type1" }.to_json)
  end

  it 'does not allow an invalid value for a parameter' do
    get("/", type: 'invalid-type')
    expect(last_response.status).to eq 400
    expect(last_response.body).to eq({ error: "type does not have a valid value" }.to_json)
  end

  context 'nil value for a parameter' do
    it 'does not allow for root params scope' do
      get("/", type: nil)
      expect(last_response.status).to eq 400
      expect(last_response.body).to eq({ error: "type does not have a valid value" }.to_json)
    end

    it 'allows for a required param in child scope' do
      get('/optional_with_required_values')
      expect(last_response.status).to eq 200
    end
  end

  it 'allows a valid default value' do
    get("/default/valid")
    expect(last_response.status).to eq 200
    expect(last_response.body).to eq({ type: "valid-type2" }.to_json)
  end

  it 'allows a proc for values' do
    get('/lambda', type: 'valid-type1')
    expect(last_response.status).to eq 200
    expect(last_response.body).to eq({ type: "valid-type1" }.to_json)
  end

  it 'does not validate updated values without proc' do
    ValuesModel.add_value('valid-type4')

    get('/', type: 'valid-type4')
    expect(last_response.status).to eq 400
    expect(last_response.body).to eq({ error: "type does not have a valid value" }.to_json)
  end

  it 'validates against values in a proc' do
    ValuesModel.add_value('valid-type4')

    get('/lambda', type: 'valid-type4')
    expect(last_response.status).to eq 200
    expect(last_response.body).to eq({ type: "valid-type4" }.to_json)
  end

  it 'does not allow an invalid value for a parameter using lambda' do
    get("/lambda", type: 'invalid-type')
    expect(last_response.status).to eq 400
    expect(last_response.body).to eq({ error: "type does not have a valid value" }.to_json)
  end


  #########################################   New tests ##############################

  context 'when type is Integer' do
    cases = {
              {}           => 200,
              { type: 5 }  => 200,
              { type: '5'} => 200,
              { type: nil }        => { error: 'type is invalid' },
              { type: 'gofish' }   => { error: 'type is invalid' },
              { type: '' }         => { error: 'type is invalid' },
              { type: ['howdy'] }  => { error: 'type is invalid' } }


    context 'when parameter is optional' do
      cases.each do |params, status_or_response_body|
        context "when params is #{params}" do
          before do
            get("/values/optional_does_not_allow_nil_for_integer", params)
          end

          it "returns #{status_or_response_body}" do
            if status_or_response_body == 200
              expect(last_response.status).to eq 200
            else
              expect(last_response.status).to eq 400
              expect(last_response.body).to eq(status_or_response_body.to_json)
            end
          end
        end
      end
    end

    context 'when parameter is required' do

      # The only difference between optional and required is
      # what happens if you don't pass that key in at all
      cases = cases.merge({} => { error: "type is missing" })

      cases.each do |params, status_or_response_body|
        context "when params is #{params}" do
          before do
            get("/values/required_does_not_allow_nil_for_integer", params)
          end

          it "returns #{status_or_response_body}" do
            if status_or_response_body == 200
              expect(last_response.status).to eq 200
            else
              expect(last_response.status).to eq 400
              expect(last_response.body).to eq(status_or_response_body.to_json)
            end
          end
        end
      end
    end
  end





  #    context 'when parameter value is an integer' do
  #      it 'does not raise an error' do
  #        get("/values/optional_does_not_allow_nil_for_integer", type: 5)
  #        expect(last_response.status).to eq 200
  #      end
  #    end

  #    context 'when parameter value is an integer-valued string' do
  #      it 'does not raise an error' do
  #        get("/values/optional_does_not_allow_nil_for_integer", type: '5')
  #        expect(last_response.status).to eq 200
  #      end
  #    end

  #    context 'when parameter is not passed in at all' do
  #      it 'does not raise an error' do
  #        get("/values/optional_does_not_allow_nil_for_integer")
  #        expect(last_response.status).to eq 200
  #      end
  #    end

  #    context 'when parameter value is explicitly set to nil' do
  #      it 'raises an error' do
  #        get("/values/optional_does_not_allow_nil_for_integer", type: nil)
  #        expect(last_response.status).to eq 400
  #        expect(last_response.body).to eq({ error: "type is invalid" }.to_json)
  #      end
  #    end

  #    context 'when parameter value is a non-numeric string' do
  #      it 'raises an error' do
  #        get("/values/optional_does_not_allow_nil_for_integer", type: 'gofish')
  #        expect(last_response.status).to eq 400
  #        expect(last_response.body).to eq({ error: "type is invalid" }.to_json)
  #      end
  #    end

  #    context 'when parameter value is an empty string' do
  #      it 'raises an error' do
  #        get("/values/optional_does_not_allow_nil_for_integer", type: '')
  #        expect(last_response.status).to eq 400
  #        expect(last_response.body).to eq({ error: "type is invalid" }.to_json)
  #      end
  #    end

  #    context 'when parameter value is an Array' do
  #      it 'raises an error' do
  #        get("/values/optional_does_not_allow_nil_for_integer", type: ['howdy'])
  #        expect(last_response.status).to eq 400
  #        expect(last_response.body).to eq({ error: "type is invalid" }.to_json)
  #      end
  #    end
  #  end

  #  context 'when parameter is required' do

  #    context 'when parameter value is an integer' do
  #      it 'does not raise an error' do
  #        get("/values/required_does_not_allow_nil_for_integer", type: 5)
  #        expect(last_response.status).to eq 200
  #      end
  #    end

  #    context 'when parameter value is an integer-valued string' do
  #      it 'does not raise an error' do
  #        get("/values/required_does_not_allow_nil_for_integer", type: '5')
  #        expect(last_response.status).to eq 200
  #      end
  #    end

  #    context 'when parameter is not passed in at all' do
  #      it 'raises an error' do
  #        get("/values/required_does_not_allow_nil_for_integer")
  #        expect(last_response.status).to eq 400
  #        expect(last_response.body).to eq({ error: "type is missing" }.to_json)
  #      end
  #    end

  #    context 'when parameter value is explicitly set to nil' do
  #      it 'raises an error' do
  #        get("/values/required_does_not_allow_nil_for_integer", type: nil)
  #        expect(last_response.status).to eq 400
  #        expect(last_response.body).to eq({ error: "type is invalid" }.to_json)
  #      end
  #    end

  #    context 'when parameter value is a non-numeric string' do
  #      it 'raises an error' do
  #        get("/values/required_does_not_allow_nil_for_integer", type: 'gofish')
  #        expect(last_response.status).to eq 400
  #        expect(last_response.body).to eq({ error: "type is invalid" }.to_json)
  #      end
  #    end

  #    context 'when parameter value is an empty string' do
  #      it 'raises an error' do
  #        get("/values/required_does_not_allow_nil_for_integer", type: '')
  #        expect(last_response.status).to eq 400
  #        expect(last_response.body).to eq({ error: "type is invalid" }.to_json)
  #      end
  #    end

  #    context 'when parameter value is an Array' do
  #      it 'raises an error' do
  #        get("/values/required_does_not_allow_nil_for_integer", type: ['howdy'])
  #        expect(last_response.status).to eq 400
  #        expect(last_response.body).to eq({ error: "type is invalid" }.to_json)
  #      end
  #    end
  #  end
  #end

  #####################################################################################

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
    expect(last_response.status).to eq 200
    expect(last_response.body).to eq({ type: 10 }.to_json)
  end

  it 'raises IncompatibleOptionValues when values contains a value that is not a kind of the type' do
    subject = Class.new(Grape::API)
    expect {
      subject.params { requires :type, values: [10.5, 11], type: Integer }
    }.to raise_error Grape::Exceptions::IncompatibleOptionValues
  end
end
