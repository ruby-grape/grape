# frozen_string_literal: true

require 'pry'

describe Grape::Validations::ContractScope do
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
    let(:schema) do
      Dry::Schema.Params do
        required(:number).filled(:integer)
      end
    end

    before do
      app.contract(schema)
      app.post('/required')
    end

    it 'coerces the parameter value one level deep' do
      post '/required', number: '1'
      expect(last_response.status).to eq(201)
      expect(validated_params).to eq('number' => 1)
    end

    it 'shows expected validation error' do
      post '/required'
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('number is missing')
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
      expect(last_response.status).to eq(201)
      expected = { 'home' => { 'address' => { 'number' => 1, 'street' => 'Baker' } }, 'turns' => [2, 3] }
      expect(validated_params).to eq(expected)
    end

    it 'shows expected validation error' do
      post '/required', home: { address: { something: 'else' } }
      expect(last_response.status).to eq(400)
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
      expect(last_response.status).to eq(201)
      expected = { 'foo_id' => 123, 'number' => 1 }
      expect(validated_params).to eq(expected)
    end

    it 'shows validation error for missing' do
      post '/foos/123/required'
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('number is missing')
    end

    it 'includes keys from all sources into declared' do
      declared_params = nil

      app.after_validation do
        declared_params = declared(params)
      end

      post '/foos/123/required', number: '1', string: '2'
      expect(last_response.status).to eq(201)
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
      expect(last_response.status).to eq(201)
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
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('foo_id is not allowed')
    end
  end
end
