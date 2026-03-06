# frozen_string_literal: true

describe Grape::Validations::Types::HashSchema do
  subject { Class.new(Grape::API) }

  let(:app) { subject }

  describe 'multiple hash schemas' do
    context 'with two different hash schemas' do
      before do
        subject.params do
          requires :value, desc: 'Price value', types: [
            hash_schema { requires :fixed_price, type: Float },
            hash_schema do
              requires :time_unit, type: String
              requires :rate, type: Float
            end
          ]
        end
        subject.post('/pricing') { params[:value].to_json }
      end

      it 'accepts the first schema variant' do
        post '/pricing', value: { fixed_price: 100.0 }
        expect(last_response.status).to eq(201)
        expect(JSON.parse(last_response.body)).to have_key('fixed_price')
      end

      it 'accepts the second schema variant' do
        post '/pricing', value: { time_unit: 'hour', rate: 50.0 }
        expect(last_response.status).to eq(201)
        result = JSON.parse(last_response.body)
        expect(result).to have_key('time_unit')
        expect(result).to have_key('rate')
      end

      it 'rejects a hash that matches neither schema' do
        post '/pricing', value: { invalid_key: 'test' }
        expect(last_response.status).to eq(400)
        expect(last_response.body).to include('does not match any of the allowed schemas')
      end

      it 'rejects incomplete first schema (missing required field)' do
        post '/pricing', value: { time_unit: 'hour' }
        expect(last_response.status).to eq(400)
        expect(last_response.body).to include('value[rate] is missing')
      end

      it 'rejects a non-hash value' do
        post '/pricing', value: 'not a hash'
        expect(last_response.status).to eq(400)
      end
    end

    context 'with coercion' do
      before do
        subject.params do
          requires :config, types: [
            hash_schema { requires :count, type: Integer },
            hash_schema { requires :enabled, type: Grape::API::Boolean }
          ]
        end
        subject.post('/config') { params[:config].to_json }
      end

      it 'accepts the first schema with coercion' do
        post '/config', config: { count: '42' }
        expect(last_response.status).to eq(201)
        result = JSON.parse(last_response.body)
        expect(result).to have_key('count')
        expect(result['count']).to eq(42)
      end

      it 'accepts the second schema with coercion' do
        post '/config', config: { enabled: 'true' }
        expect(last_response.status).to eq(201)
        result = JSON.parse(last_response.body)
        expect(result).to have_key('enabled')
        expect(result['enabled']).to be(true)
      end

      it 'rejects invalid type for first schema' do
        post '/config', config: { count: 'not a number' }
        expect(last_response.status).to eq(400)
        expect(last_response.body).to include('config[count] is invalid')
      end
    end

    context 'with nested hash schemas' do
      before do
        subject.params do
          requires :options, types: [
            hash_schema do
              requires :form, type: Hash do
                requires :colour, type: String
                requires :font, type: String
                optional :size, type: Integer
              end
            end,
            hash_schema do
              requires :api, type: Hash do
                requires :authenticated, type: Grape::API::Boolean
              end
            end
          ]
        end
        subject.post('/settings') { params[:options].to_json }
      end

      it 'accepts first schema with all required nested fields' do
        post '/settings', options: { form: { colour: 'red', font: 'Arial' } }
        expect(last_response.status).to eq(201)
        result = JSON.parse(last_response.body)
        expect(result['form']['colour']).to eq('red')
        expect(result['form']['font']).to eq('Arial')
      end

      it 'accepts first schema with optional nested field' do
        post '/settings', options: { form: { colour: 'blue', font: 'Helvetica', size: 12 } }
        expect(last_response.status).to eq(201)
        result = JSON.parse(last_response.body)
        expect(result['form']['size']).to eq(12)
      end

      it 'rejects first schema when missing required nested field (colour)' do
        post '/settings', options: { form: { font: 'Arial' } }
        expect(last_response.status).to eq(400)
        expect(last_response.body).to include('options[form][colour] is missing')
      end

      it 'rejects first schema when missing required nested field (font)' do
        post '/settings', options: { form: { colour: 'red' } }
        expect(last_response.status).to eq(400)
        expect(last_response.body).to include('options[form][font] is missing')
      end

      it 'accepts second schema with required nested field' do
        post '/settings', options: { api: { authenticated: true } }
        expect(last_response.status).to eq(201)
        result = JSON.parse(last_response.body)
        expect(result['api']['authenticated']).to be(true)
      end

      it 'rejects second schema when missing required nested field' do
        # Use JSON encoding for empty nested hashes as form encoding doesn't handle them properly
        header 'Content-Type', 'application/json'
        post '/settings', { options: { api: {} } }.to_json
        expect(last_response.status).to eq(400)
        expect(last_response.body).to include('options[api][authenticated] is missing')
      end

      it 'validates nested field types' do
        post '/settings', options: { form: { colour: 'red', font: 'Arial', size: 'not a number' } }
        expect(last_response.status).to eq(400)
        expect(last_response.body).to include('options[form][size] is invalid')
      end

      it 'coerces nested boolean fields' do
        post '/settings', options: { api: { authenticated: 'true' } }
        expect(last_response.status).to eq(201)
        result = JSON.parse(last_response.body)
        expect(result['api']['authenticated']).to be(true)
      end

      it 'reports all missing nested fields at once' do
        # Send a hash with the form key present but empty nested hash
        header 'Content-Type', 'application/json'
        post '/settings', { options: { form: {} } }.to_json
        expect(last_response.status).to eq(400)
        # Should include both missing fields in the error message
        expect(last_response.body).to include('options[form][colour] is missing')
        expect(last_response.body).to include('options[form][font] is missing')
      end
    end

    context 'with complex nested structures' do
      before do
        subject.params do
          requires :data, types: [
            hash_schema do
              requires :user, type: Hash do
                requires :name, type: String
                requires :age, type: Integer
                optional :email, type: String
              end
            end,
            hash_schema do
              requires :product, type: Hash do
                requires :id, type: Integer
                requires :price, type: Float
              end
            end
          ]
        end
        subject.post('/data') { params[:data].to_json }
      end

      it 'validates deeply nested required fields in first schema' do
        post '/data', data: { user: { name: 'John', age: 30 } }
        expect(last_response.status).to eq(201)
      end

      it 'rejects first schema when nested required field is missing' do
        post '/data', data: { user: { name: 'John' } }
        expect(last_response.status).to eq(400)
        expect(last_response.body).to include('data[user][age] is missing')
      end

      it 'validates deeply nested required fields in second schema' do
        post '/data', data: { product: { id: 123, price: 19.99 } }
        expect(last_response.status).to eq(201)
      end

      it 'coerces nested integer fields' do
        post '/data', data: { user: { name: 'John', age: '30' } }
        expect(last_response.status).to eq(201)
        result = JSON.parse(last_response.body)
        expect(result['user']['age']).to eq(30)
      end
    end
  end
end
