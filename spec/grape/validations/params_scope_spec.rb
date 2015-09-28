require 'spec_helper'

describe Grape::Validations::ParamsScope do
  subject do
    Class.new(Grape::API)
  end

  def app
    subject
  end

  context 'setting a default' do
    let(:documentation) { subject.routes.first.route_params }

    context 'when the default value is truthy' do
      before do
        subject.params do
          optional :int, type: Integer, default: 42
        end
        subject.get
      end

      it 'adds documentation about the default value' do
        expect(documentation).to have_key('int')
        expect(documentation['int']).to have_key(:default)
        expect(documentation['int'][:default]).to eq(42)
      end
    end

    context 'when the default value is false' do
      before do
        subject.params do
          optional :bool, type: Virtus::Attribute::Boolean, default: false
        end
        subject.get
      end

      it 'adds documentation about the default value' do
        expect(documentation).to have_key('bool')
        expect(documentation['bool']).to have_key(:default)
        expect(documentation['bool'][:default]).to eq(false)
      end
    end

    context 'when the default value is nil' do
      before do
        subject.params do
          optional :object, type: Object, default: nil
        end
        subject.get
      end

      it 'adds documentation about the default value' do
        expect(documentation).to have_key('object')
        expect(documentation['object']).to have_key(:default)
        expect(documentation['object'][:default]).to eq(nil)
      end
    end
  end

  context 'without a default' do
    before do
      subject.params do
        optional :object, type: Object
      end
      subject.get
    end

    it 'does not add documentation for the default value' do
      documentation = subject.routes.first.route_params
      expect(documentation).to have_key('object')
      expect(documentation['object']).not_to have_key(:default)
    end
  end

  context 'setting description' do
    [:desc, :description].each do |description_type|
      it "allows setting #{description_type}" do
        subject.params do
          requires :int, type: Integer, description_type => 'My very nice integer'
        end
        subject.get '/single' do
          'int works'
        end
        get '/single', int: 420
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('int works')
      end
    end
  end

  context 'when using custom types' do
    module ParamsScopeSpec
      class CustomType
        attr_reader :value
        def self.parse(value)
          fail if value == 'invalid'
          new(value)
        end

        def initialize(value)
          @value = value
        end
      end
    end

    it 'coerces the parameter via the type\'s parse method' do
      subject.params do
        requires :foo, type: ParamsScopeSpec::CustomType
      end
      subject.get('/types') { params[:foo].value }

      get '/types', foo: 'valid'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('valid')

      get '/types', foo: 'invalid'
      expect(last_response.status).to eq(400)
      expect(last_response.body).to match(/foo is invalid/)
    end
  end

  context 'array without coerce type explicitly given' do
    it 'sets the type based on first element' do
      subject.params do
        requires :periods, type: Array, values: -> { %w(day month) }
      end
      subject.get('/required') { 'required works' }

      get '/required', periods: %w(day month)
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('required works')
    end

    it 'fails to call API without Array type' do
      subject.params do
        requires :periods, type: Array, values: -> { %w(day month) }
      end
      subject.get('/required') { 'required works' }

      get '/required', periods: 'day'
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('periods is invalid')
    end

    it 'raises exception when values are of different type' do
      expect do
        subject.params { requires :numbers, type: Array, values: [1, 'definitely not a number', 3] }
      end.to raise_error Grape::Exceptions::IncompatibleOptionValues
    end

    it 'raises exception when range values have different endpoint types' do
      expect do
        subject.params { requires :numbers, type: Array, values: 0.0..10 }
      end.to raise_error Grape::Exceptions::IncompatibleOptionValues
    end
  end

  context 'with range values' do
    context "when left range endpoint isn't #kind_of? the type" do
      it 'raises exception' do
        expect do
          subject.params { requires :latitude, type: Integer, values: -90.0..90 }
        end.to raise_error Grape::Exceptions::IncompatibleOptionValues
      end
    end

    context "when right range endpoint isn't #kind_of? the type" do
      it 'raises exception' do
        expect do
          subject.params { requires :latitude, type: Integer, values: -90..90.0 }
        end.to raise_error Grape::Exceptions::IncompatibleOptionValues
      end
    end

    context 'when both range endpoints are #kind_of? the type' do
      it 'accepts values in the range' do
        subject.params do
          requires :letter, type: String, values: 'a'..'z'
        end
        subject.get('/letter') { params[:letter] }

        get '/letter', letter: 'j'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('j')
      end

      it 'rejects values outside the range' do
        subject.params do
          requires :letter, type: String, values: 'a'..'z'
        end
        subject.get('/letter') { params[:letter] }

        get '/letter', letter: 'J'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('letter does not have a valid value')
      end
    end
  end

  context 'parameters in group' do
    it 'errors when no type is provided' do
      expect do
        subject.params do
          group :a do
            requires :b
          end
        end
      end.to raise_error Grape::Exceptions::MissingGroupTypeError

      expect do
        subject.params do
          optional :a do
            requires :b
          end
        end
      end.to raise_error Grape::Exceptions::MissingGroupTypeError
    end

    it 'allows Hash as type' do
      subject.params do
        group :a, type: Hash do
          requires :b
        end
      end
      subject.get('/group') { 'group works' }
      get '/group', a: { b: true }
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('group works')

      subject.params do
        optional :a, type: Hash do
          requires :b
        end
      end
      get '/optional_type_hash'
    end

    it 'allows Array as type' do
      subject.params do
        group :a, type: Array do
          requires :b
        end
      end
      subject.get('/group') { 'group works' }
      get '/group', a: [{ b: true }]
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('group works')

      subject.params do
        optional :a, type: Array do
          requires :b
        end
      end
      get '/optional_type_array'
    end

    it 'errors with an unsupported type' do
      expect do
        subject.params do
          group :a, type: Set do
            requires :b
          end
        end
      end.to raise_error Grape::Exceptions::UnsupportedGroupTypeError

      expect do
        subject.params do
          optional :a, type: Set do
            requires :b
          end
        end
      end.to raise_error Grape::Exceptions::UnsupportedGroupTypeError
    end
  end

  context 'when validations are dependent on a parameter' do
    before do
      subject.params do
        optional :a
        given :a do
          requires :b
        end
      end
      subject.get('/test') { declared(params).to_json }
    end

    it 'applies the validations only if the parameter is present' do
      get '/test'
      expect(last_response.status).to eq(200)

      get '/test', a: true
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('b is missing')

      get '/test', a: true, b: true
      expect(last_response.status).to eq(200)
    end

    it 'raises an error if the dependent parameter was never specified' do
      expect do
        subject.params do
          given :c do
          end
        end
      end.to raise_error(Grape::Exceptions::UnknownParameter)
    end

    it 'includes the parameter within #declared(params)' do
      get '/test', a: true, b: true

      expect(JSON.parse(last_response.body)).to eq('a' => 'true', 'b' => 'true')
    end

    it 'returns a sensible error message within a nested context' do
      subject.params do
        requires :bar, type: Hash do
          optional :a
          given :a do
            requires :b
          end
        end
      end
      subject.get('/nested') { 'worked' }

      get '/nested', bar: { a: true }
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('bar[b] is missing')
    end
  end
end
