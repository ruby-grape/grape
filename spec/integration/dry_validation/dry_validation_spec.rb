# frozen_string_literal: true

describe 'Dry::Schema', if: defined?(Dry::Schema) do
  describe 'Grape::DSL::Validations' do
    subject { app }

    let(:app) do
      Class.new do
        include Grape::DSL::Validations
      end
    end

    describe '.reset_validations!' do
      before do
        subject.namespace_stackable :declared_params, ['dummy']
        subject.namespace_stackable :validations, ['dummy']
        subject.namespace_stackable :params, ['dummy']
        subject.route_setting :description, description: 'lol', params: ['dummy']
        subject.reset_validations!
      end

      after do
        subject.unset_route_setting :description
      end

      it 'resets declared params' do
        expect(subject.namespace_stackable(:declared_params)).to be_empty
      end

      it 'resets validations' do
        expect(subject.namespace_stackable(:validations)).to be_empty
      end

      it 'resets params' do
        expect(subject.namespace_stackable(:params)).to be_empty
      end

      it 'does not reset documentation description' do
        expect(subject.route_setting(:description)[:description]).to eq 'lol'
      end
    end

    describe '.params' do
      it 'returns a ParamsScope' do
        expect(subject.params).to be_a Grape::Validations::ParamsScope
      end

      it 'evaluates block' do
        expect { subject.params { raise 'foo' } }.to raise_error RuntimeError, 'foo'
      end
    end

    describe '.contract' do
      it 'saves the schema instance' do
        expect(subject.contract(Dry::Schema.Params)).to be_a Grape::Validations::ContractScope
      end

      it 'errors without params or block' do
        expect { subject.contract }.to raise_error(ArgumentError)
      end
    end
  end

  describe 'Grape::Validations::ContractScope' do
    let(:validated_params) { {} }
    let(:app) do
      vp = validated_params

      Class.new(Grape::API) do
        after_validation do
          vp.replace(params)
        end
      end
    end

    context 'with simple schema, pre-defined' do
      let(:contract) do
        Dry::Schema.Params do
          required(:number).filled(:integer)
        end
      end

      before do
        app.contract(contract)
        app.post('/required')
      end

      it 'coerces the parameter value one level deep' do
        post '/required', number: '1'
        expect(last_response).to be_created
        expect(validated_params).to eq('number' => 1)
      end

      it 'shows expected validation error' do
        post '/required'
        expect(last_response).to be_bad_request
        expect(last_response.body).to eq('number is missing')
      end
    end

    context 'with contract class' do
      let(:contract) do
        Class.new(Dry::Validation::Contract) do
          params do
            required(:number).filled(:integer)
            required(:name).filled(:string)
          end

          rule(:number) do
            key.failure('is too high') if value > 5
          end
        end
      end

      before do
        app.contract(contract)
        app.post('/required')
      end

      it 'coerces the parameter' do
        post '/required', number: '1', name: '2'
        expect(last_response).to be_created
        expect(validated_params).to eq('number' => 1, 'name' => '2')
      end

      it 'shows expected validation error' do
        post '/required', number: '6'
        expect(last_response).to be_bad_request
        expect(last_response.body).to eq('name is missing, number is too high')
      end
    end

    context 'with nested schema' do
      before do
        app.contract do
          required(:home).hash do
            required(:address).hash do
              required(:number).filled(:integer)
            end
          end
          required(:turns).array(:integer)
        end

        app.post('/required')
      end

      it 'keeps unknown parameters' do
        post '/required', home: { address: { number: '1', street: 'Baker' } }, turns: %w[2 3]
        expect(last_response).to be_created
        expected = { 'home' => { 'address' => { 'number' => 1, 'street' => 'Baker' } }, 'turns' => [2, 3] }
        expect(validated_params).to eq(expected)
      end

      it 'shows expected validation error' do
        post '/required', home: { address: { something: 'else' } }
        expect(last_response).to be_bad_request
        expect(last_response.body).to eq('home[address][number] is missing, turns is missing')
      end
    end

    context 'with mixed validation sources' do
      before do
        app.resource :foos do
          route_param :foo_id, type: Integer do
            contract do
              required(:number).filled(:integer)
            end
            post('/required')
          end
        end
      end

      it 'combines the coercions' do
        post '/foos/123/required', number: '1'
        expect(last_response).to be_created
        expected = { 'foo_id' => 123, 'number' => 1 }
        expect(validated_params).to eq(expected)
      end

      it 'shows validation error for missing' do
        post '/foos/123/required'
        expect(last_response).to be_bad_request
        expect(last_response.body).to eq('number is missing')
      end

      it 'includes keys from all sources into declared' do
        declared_params = nil

        app.after_validation do
          declared_params = declared(params)
        end

        post '/foos/123/required', number: '1', string: '2'
        expect(last_response).to be_created
        expected = { 'foo_id' => 123, 'number' => 1 }
        expect(validated_params).to eq(expected.merge('string' => '2'))
        expect(declared_params).to eq(expected)
      end
    end

    context 'with schema config validate_keys=true' do
      it 'validates the whole params hash' do
        app.resource :foos do
          route_param :foo_id do
            contract do
              config.validate_keys = true

              required(:number).filled(:integer)
              required(:foo_id).filled(:integer)
            end
            post('/required')
          end
        end

        post '/foos/123/required', number: '1'
        expect(last_response).to be_created
        expected = { 'foo_id' => 123, 'number' => 1 }
        expect(validated_params).to eq(expected)
      end

      it 'fails validation for any parameters not in schema' do
        app.resource :foos do
          route_param :foo_id, type: Integer do
            contract do
              config.validate_keys = true

              required(:number).filled(:integer)
            end
            post('/required')
          end
        end

        post '/foos/123/required', number: '1'
        expect(last_response).to be_bad_request
        expect(last_response.body).to eq('foo_id is not allowed')
      end
    end
  end
end
