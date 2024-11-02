# frozen_string_literal: true

describe 'Hashie', if: defined?(Hashie) do
  subject { Class.new(Grape::API) }

  let(:app) { subject }

  describe 'Grape::Extensions::Hashie::Mash::ParamBuilder' do
    describe 'in an endpoint' do
      describe '#params' do
        before do
          subject.params do
            build_with Grape::Extensions::Hashie::Mash::ParamBuilder
          end

          subject.get do
            params.class
          end
        end

        it 'is of type Hashie::Mash' do
          get '/'
          expect(last_response).to be_successful
          expect(last_response.body).to eq('Hashie::Mash')
        end
      end
    end

    describe 'in an api' do
      before do
        subject.include Grape::Extensions::Hashie::Mash::ParamBuilder
      end

      describe '#params' do
        before do
          subject.get do
            params.class
          end
        end

        it 'is Hashie::Mash' do
          get '/'
          expect(last_response).to be_successful
          expect(last_response.body).to eq('Hashie::Mash')
        end
      end

      context 'in a nested namespace api' do
        before do
          subject.namespace :foo do
            get do
              params.class
            end
          end
        end

        it 'is Hashie::Mash' do
          get '/foo'
          expect(last_response).to be_successful
          expect(last_response.body).to eq('Hashie::Mash')
        end
      end

      it 'is indifferent to key or symbol access' do
        subject.params do
          build_with Grape::Extensions::Hashie::Mash::ParamBuilder
          requires :a, type: String
        end
        subject.get '/foo' do
          [params[:a], params['a']]
        end

        get '/foo', a: 'bar'
        expect(last_response).to be_successful
        expect(last_response.body).to eq('["bar", "bar"]')
      end

      it 'does not overwrite route_param with a regular param if they have same name' do
        subject.namespace :route_param do
          route_param :foo do
            get { params.to_json }
          end
        end

        get '/route_param/bar', foo: 'baz'
        expect(last_response).to be_successful
        expect(last_response.body).to eq('{"foo":"bar"}')
      end

      it 'does not overwrite route_param with a defined regular param if they have same name' do
        subject.namespace :route_param do
          params do
            build_with Grape::Extensions::Hashie::Mash::ParamBuilder
            requires :foo, type: String
          end
          route_param :foo do
            get do
              [params[:foo], params['foo']]
            end
          end
        end

        get '/route_param/bar', foo: 'baz'
        expect(last_response).to be_successful
        expect(last_response.body).to eq('["bar", "bar"]')
      end
    end
  end

  describe 'Grape::Request' do
    let(:default_method) { Rack::GET }
    let(:default_params) { {} }
    let(:default_options) do
      {
        method: method,
        params: params
      }
    end
    let(:default_env) do
      Rack::MockRequest.env_for('/', options)
    end
    let(:method) { default_method }
    let(:params) { default_params }
    let(:options) { default_options }
    let(:env) { default_env }
    let(:request) { Grape::Request.new(env) }

    describe '#params' do
      let(:params) do
        {
          a: '123',
          b: 'xyz'
        }
      end

      it 'by default returns stringified parameter keys' do
        expect(request.params).to eq(ActiveSupport::HashWithIndifferentAccess.new('a' => '123', 'b' => 'xyz'))
      end

      context 'when build_params_with: Grape::Extensions::Hash::ParamBuilder is specified' do
        let(:request) { Grape::Request.new(env, build_params_with: Grape::Extensions::Hash::ParamBuilder) }

        it 'returns symbolized params' do
          expect(request.params).to eq(a: '123', b: 'xyz')
        end
      end

      describe 'with grape.routing_args' do
        let(:options) do
          default_options.merge('grape.routing_args' => routing_args)
        end
        let(:routing_args) do
          {
            version: '123',
            route_info: '456',
            c: 'ccc'
          }
        end

        it 'cuts version and route_info' do
          expect(request.params).to eq(ActiveSupport::HashWithIndifferentAccess.new(a: '123', b: 'xyz', c: 'ccc'))
        end
      end
    end

    describe 'when the build_params_with is set to Hashie' do
      subject(:request_params) { Grape::Request.new(env, build_params_with: Grape::Extensions::Hashie::Mash::ParamBuilder).params }

      context 'when the API includes a specific param builder' do
        it { is_expected.to be_a(Hashie::Mash) }
      end
    end
  end

  describe 'Grape::Validations::Validators::CoerceValidator' do
    context 'when params is Hashie::Mash' do
      context 'for primitive collections' do
        before do
          subject.params do
            build_with Grape::Extensions::Hashie::Mash::ParamBuilder
            optional :a, types: [String, Array[String]]
            optional :b, types: [Array[Integer], Array[String]]
            optional :c, type: Array[Integer, String]
            optional :d, types: [Integer, String, Set[Integer, String]]
          end
          subject.get '/' do
            (
              params.a ||
                params.b ||
                params.c ||
                params.d
            ).inspect
          end
        end

        it 'allows singular form declaration' do
          get '/', a: 'one way'
          expect(last_response).to be_successful
          expect(last_response.body).to eq('"one way"')

          get '/', a: %w[the other]
          expect(last_response).to be_successful
          expect(last_response.body).to eq('#<Hashie::Array ["the", "other"]>')

          get '/', a: { a: 1, b: 2 }
          expect(last_response).to be_bad_request
          expect(last_response.body).to eq('a is invalid')

          get '/', a: [1, 2, 3]
          expect(last_response).to be_successful
          expect(last_response.body).to eq('#<Hashie::Array ["1", "2", "3"]>')
        end

        it 'allows multiple collection types' do
          get '/', b: [1, 2, 3]
          expect(last_response).to be_successful
          expect(last_response.body).to eq('#<Hashie::Array [1, 2, 3]>')

          get '/', b: %w[1 2 3]
          expect(last_response).to be_successful
          expect(last_response.body).to eq('#<Hashie::Array [1, 2, 3]>')

          get '/', b: [1, true, 'three']
          expect(last_response).to be_successful
          expect(last_response.body).to eq('#<Hashie::Array ["1", "true", "three"]>')
        end

        it 'allows collections with multiple types' do
          get '/', c: [1, '2', true, 'three']
          expect(last_response).to be_successful
          expect(last_response.body).to eq('#<Hashie::Array [1, 2, "true", "three"]>')

          get '/', d: '1'
          expect(last_response).to be_successful
          expect(last_response.body).to eq('1')

          get '/', d: 'one'
          expect(last_response).to be_successful
          expect(last_response.body).to eq('"one"')

          get '/', d: %w[1 two]
          expect(last_response).to be_successful
          expect(last_response.body).to eq('#<Set: {1, "two"}>')
        end
      end
    end
  end

  describe 'Grape::Endpoint' do
    before do
      subject.format :json
      subject.params do
        requires :first
        optional :second
        optional :third, default: 'third-default'
        optional :multiple_types, types: [Integer, String]
        optional :nested, type: Hash do
          optional :fourth
          optional :fifth
          optional :nested_two, type: Hash do
            optional :sixth
            optional :nested_three, type: Hash do
              optional :seventh
            end
          end
          optional :nested_arr, type: Array do
            optional :eighth
          end
          optional :empty_arr, type: Array
          optional :empty_typed_arr, type: Array[String]
          optional :empty_hash, type: Hash
          optional :empty_set, type: Set
          optional :empty_typed_set, type: Set[String]
        end
        optional :arr, type: Array do
          optional :nineth
        end
        optional :empty_arr, type: Array
        optional :empty_typed_arr, type: Array[String]
        optional :empty_hash, type: Hash
        optional :empty_hash_two, type: Hash
        optional :empty_set, type: Set
        optional :empty_typed_set, type: Set[String]
      end
    end

    context 'when params are not built with default class' do
      it 'returns an object that corresponds with the params class - hashie mash' do
        subject.params do
          build_with Grape::Extensions::Hashie::Mash::ParamBuilder
        end
        subject.get '/declared' do
          d = declared(params, include_missing: true)
          { declared_class: d.class.to_s }
        end

        get '/declared?first=present'
        expect(JSON.parse(last_response.body)['declared_class']).to eq('Hashie::Mash')
      end
    end
  end
end
