# frozen_string_literal: true

describe Grape::Validations::Validators::OneofValidator do
  describe 'definition-time validation' do
    it 'raises when type: Hash is missing' do
      expect do
        Class.new(Grape::API) do
          params do
            requires :value, oneof: [proc { requires :a, type: Integer }]
          end
          post('/') {}
        end
      end.to raise_error(ArgumentError, /requires type: Hash/)
    end

    it 'raises when oneof is not an array' do
      expect do
        Class.new(Grape::API) do
          params do
            requires :value, type: Hash, oneof: proc { requires :a }
          end
          post('/') {}
        end
      end.to raise_error(ArgumentError, /non-empty Array of blocks/)
    end

    it 'raises when oneof is empty' do
      expect do
        Class.new(Grape::API) do
          params do
            requires :value, type: Hash, oneof: []
          end
          post('/') {}
        end
      end.to raise_error(ArgumentError, /non-empty Array of blocks/)
    end

    it 'raises when a variant is not a Proc' do
      expect do
        Class.new(Grape::API) do
          params do
            requires :value, type: Hash, oneof: ['not a proc']
          end
          post('/') {}
        end
      end.to raise_error(ArgumentError, /each variant must be a Proc/)
    end
  end

  describe 'request-time validation with two flat variants' do
    let(:app) do
      Class.new(Grape::API) do
        format :json
        params do
          requires :value, type: Hash, oneof: [
            proc { requires :fixed_price, type: Float },
            proc do
              requires :time_unit, type: String
              requires :rate, type: Float
            end
          ]
        end
        post('/pricing') { params[:value] }
      end
    end

    it 'matches the first variant' do
      post '/pricing', { value: { fixed_price: 100.0 } }.to_json, 'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to eq(201)
      expect(JSON.parse(last_response.body)).to eq('fixed_price' => 100.0)
    end

    it 'matches the second variant' do
      post '/pricing', { value: { time_unit: 'hour', rate: 50.0 } }.to_json, 'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to eq(201)
      expect(JSON.parse(last_response.body)).to eq('time_unit' => 'hour', 'rate' => 50.0)
    end

    it 'coerces values inside the winning variant' do
      post '/pricing', { value: { fixed_price: '150.5' } }.to_json, 'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to eq(201)
      expect(JSON.parse(last_response.body)).to eq('fixed_price' => 150.5)
    end

    it 'rejects values that do not match any variant' do
      post '/pricing', { value: { time_unit: 'hour', rate: 'not-a-number' } }.to_json, 'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to eq(400)
      expect(JSON.parse(last_response.body)['error']).to match(/does not match any of the allowed schemas/)
    end

    it 'rejects values with no matching keys' do
      post '/pricing', { value: { something_else: 1 } }.to_json, 'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to eq(400)
      expect(JSON.parse(last_response.body)['error']).to match(/does not match any of the allowed schemas/)
    end

    it 'rejects when the value key is missing entirely' do
      post '/pricing', '{}', 'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to eq(400)
      expect(JSON.parse(last_response.body)['error']).to match(/value is missing/)
    end
  end

  describe 'optional :value' do
    let(:app) do
      Class.new(Grape::API) do
        format :json
        params do
          optional :value, type: Hash, oneof: [
            proc { requires :a, type: Integer }
          ]
        end
        post('/') { { value: params[:value] } }
      end
    end

    it 'accepts a missing value' do
      post '/', '{}', 'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to eq(201)
    end

    it 'still validates when the value is provided' do
      post '/', { value: { a: 'oops' } }.to_json, 'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to eq(400)
    end
  end

  describe 'full DSL inside a variant' do
    let(:app) do
      Class.new(Grape::API) do
        format :json
        params do
          requires :value, type: Hash, oneof: [
            proc { requires :state, type: Symbol, values: %i[active inactive] },
            proc { requires :name, type: String, regexp: /\A[a-z]+\z/ }
          ]
        end
        post('/') { params[:value] }
      end
    end

    it 'enforces values: inside a variant' do
      post '/', { value: { state: 'unknown' } }.to_json, 'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to eq(400)
    end

    it 'accepts a value that matches the values: constraint' do
      post '/', { value: { state: 'active' } }.to_json, 'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to eq(201)
    end

    it 'falls through to the second variant when the first fails' do
      post '/', { value: { name: 'alice' } }.to_json, 'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to eq(201)
    end

    it 'enforces regexp: inside a variant' do
      post '/', { value: { name: 'NoCaps' } }.to_json, 'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to eq(400)
    end
  end

  describe 'nested hash inside a variant' do
    let(:app) do
      Class.new(Grape::API) do
        format :json
        params do
          requires :options, type: Hash, oneof: [
            proc do
              requires :form, type: Hash do
                requires :colour, type: String
                optional :size, type: Integer
              end
            end,
            proc do
              requires :api, type: Hash do
                requires :authenticated, type: Grape::API::Boolean
              end
            end
          ]
        end
        post('/') { params[:options] }
      end
    end

    it 'matches a deeply nested first variant' do
      post '/', { options: { form: { colour: 'red', size: 12 } } }.to_json, 'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to eq(201)
      expect(JSON.parse(last_response.body)).to eq('form' => { 'colour' => 'red', 'size' => 12 })
    end

    it 'matches a deeply nested second variant' do
      post '/', { options: { api: { authenticated: 'true' } } }.to_json, 'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to eq(201)
      expect(JSON.parse(last_response.body)).to eq('api' => { 'authenticated' => true })
    end

    it 'rejects when a required nested field is missing' do
      post '/', { options: { form: {} } }.to_json, 'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to eq(400)
    end
  end
end
