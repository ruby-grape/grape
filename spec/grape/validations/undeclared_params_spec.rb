# frozen_string_literal: true

describe Grape::Validations::UndeclaredParams do
  let(:app) do
    Class.new(Grape::API) do
      format :json

      params do
        requires :name, type: String
      end
      post '/users' do
        params
      end
    end
  end

  def post_json(path, body)
    post path, body.to_json, 'CONTENT_TYPE' => 'application/json'
  end

  context 'when Grape.config.allow_undeclared_params is not set' do
    it 'hands the endpoint the params it did not declare' do
      post_json '/users', name: 'Bob', admin: true
      expect(last_response).to be_created
      expect(JSON.parse(last_response.body)).to eq('name' => 'Bob', 'admin' => true)
    end
  end

  context 'when Grape.config.allow_undeclared_params is false' do
    around do |example|
      Grape.config.allow_undeclared_params = false
      example.run
    ensure
      Grape.config.allow_undeclared_params = true
    end

    it 'answers 400 to a param the endpoint did not declare' do
      post_json '/users', name: 'Bob', admin: true
      expect(last_response).to be_bad_request
      expect(last_response.body).to eq('{"error":"admin is not allowed"}')
    end

    it 'answers a query param it did not declare like a body param' do
      post '/users?admin=true', { name: 'Bob' }.to_json, 'CONTENT_TYPE' => 'application/json'
      expect(last_response).to be_bad_request
      expect(last_response.body).to eq('{"error":"admin is not allowed"}')
    end

    it 'serves a request that sends only what is declared' do
      post_json '/users', name: 'Bob'
      expect(last_response).to be_created
      expect(JSON.parse(last_response.body)).to eq('name' => 'Bob')
    end

    it 'reports undeclared params along with the other validation errors' do
      post_json '/users', admin: true, role: 'root'
      expect(last_response).to be_bad_request
      expect(last_response.body).to eq('{"error":"name is missing, admin is not allowed, role is not allowed"}')
    end

    context 'with a rescue_from for validation errors' do
      let(:app) do
        Class.new(Grape::API) do
          format :json
          rescue_from(Grape::Exceptions::ValidationErrors) { |e| error!(e.errors.transform_keys { |k| k.join(',') }, 422) }

          params do
            requires :name, type: String
          end
          post('/users') { params }
        end
      end

      it 'raises them as Grape::Exceptions::ValidationErrors' do
        post_json '/users', name: 'Bob', admin: true
        expect(last_response.status).to eq(422)
        expect(JSON.parse(last_response.body)).to eq('admin' => ['is not allowed'])
      end
    end

    context 'with nested params' do
      let(:app) do
        Class.new(Grape::API) do
          format :json

          params do
            optional :address, type: Hash do
              requires :street, type: String
            end
            optional :items, type: Array do
              requires :sku, type: String
              optional :parts, type: Array do
                optional :serial, type: String
              end
            end
            optional :settings, type: JSON do
              optional :theme, type: String
            end
            optional :metadata, type: Hash
            optional :tags, type: Array[String]
          end
          post '/orders' do
            params
          end
        end
      end

      it 'names an undeclared key of a Hash by its path' do
        post_json '/orders', address: { street: 'Main', zip: '1' }
        expect(last_response).to be_bad_request
        expect(last_response.body).to eq('{"error":"address[zip] is not allowed"}')
      end

      it 'names an undeclared key of an Array element by its index' do
        post_json '/orders', items: [{ sku: 'a' }, { sku: 'b', price: 1, parts: [{ serial: 's', batch: 2 }] }]
        expect(last_response).to be_bad_request
        expect(last_response.body).to eq('{"error":"items[1][price] is not allowed, items[1][parts][0][batch] is not allowed"}')
      end

      it 'looks into a JSON param sent as a String' do
        post_json '/orders', settings: { theme: 'dark', admin: true }.to_json
        expect(last_response).to be_bad_request
        expect(last_response.body).to eq('{"error":"settings[admin] is not allowed"}')
      end

      it 'looks into each element of a JSON param sent as an Array' do
        post_json '/orders', settings: [{ theme: 'dark' }, { admin: true }]
        expect(last_response).to be_bad_request
        expect(last_response.body).to eq('{"error":"settings[1][admin] is not allowed"}')
      end

      it 'leaves a value that is not a Hash where one is declared to its validators' do
        post_json '/orders', address: 'Main', items: ['a']
        expect(last_response).to be_bad_request
        expect(last_response.body).to start_with('{"error":"address is invalid')
        expect(last_response.body).not_to include('is not allowed')
      end

      it 'takes anything in a param declared without a block' do
        post_json '/orders', metadata: { anything: { goes: 1 } }, tags: %w[a b]
        expect(last_response).to be_created
      end
    end

    context 'with params the endpoint does not declare itself' do
      let(:app) do
        Class.new(Grape::API) do
          format :json

          params do
            requires :account_id, type: Integer
          end
          namespace 'accounts/:account_id' do
            params do
              requires :name, type: String, as: :full_name
              optional :kind, type: String
              given :kind do
                requires :extra, type: String
              end
            end
            post 'users/:id' do
              declared(params)
            end
          end
        end
      end

      it 'accepts its path params, its namespace params, a renamed param by its name, a given param and the format' do
        post_json '/accounts/1/users/2?format=json', name: 'Bob', kind: 'k', extra: 'e'
        expect(last_response).to be_created
        expect(JSON.parse(last_response.body)).to eq('account_id' => 1, 'full_name' => 'Bob', 'kind' => 'k', 'extra' => 'e')
      end
    end

    context 'with a param declared in more than one given' do
      let(:app) do
        Class.new(Grape::API) do
          format :json

          params do
            requires :kind, type: String, values: %w[card bank any]
            given kind: ->(kind) { kind == 'any' } do
              requires :payment, type: Hash
            end
            given kind: ->(kind) { kind == 'card' } do
              requires :payment, type: Hash do
                requires :number, type: String
              end
            end
            given kind: ->(kind) { kind == 'bank' } do
              requires :payment, type: Hash do
                requires :iban, type: String
              end
            end
          end
          post('/payments') { params }
        end
      end

      it 'accepts the keys of every declaration, and anything when one declares no block' do
        post_json '/payments', kind: 'bank', payment: { iban: 'DE00', number: '4111' }
        expect(last_response).to be_created

        post_json '/payments', kind: 'any', payment: { token: 't' }
        expect(last_response).to be_created
      end
    end

    context 'with mounted apps' do
      let(:app) do
        users = Class.new(Grape::API) do
          params do
            requires :name, type: String
          end
          post('/users') { params[:name] }
        end

        Class.new(Grape::API) do
          mount users
          mount ->(_env) { [200, {}, ['raw']] } => '/raw'
        end
      end

      it 'looks at the endpoints of a mounted API' do
        post '/users', name: 'Bob', admin: true
        expect(last_response).to be_bad_request
        expect(last_response.body).to eq('admin is not allowed')
      end

      it 'leaves a mounted Rack app its params' do
        get '/raw?anything=1'
        expect(last_response).to be_ok
        expect(last_response.body).to eq('raw')
      end
    end

    context 'with an endpoint that declares no params' do
      let(:app) do
        Class.new(Grape::API) do
          get('/ping') { 'pong' }
        end
      end

      it 'serves a request that sends none' do
        get '/ping'
        expect(last_response).to be_ok
      end

      it 'answers 400 to one that sends any' do
        get '/ping?cache_buster=1'
        expect(last_response).to be_bad_request
        expect(last_response.body).to eq('cache_buster is not allowed')
      end
    end

    context 'with the :hash params builder' do
      let(:app) do
        Class.new(Grape::API) do
          format :json
          build_with :hash

          params do
            optional :address, type: Hash do
              requires :street, type: String
            end
          end
          post '/users/:id' do
            params
          end
        end
      end

      it 'reads Symbol keys like String ones' do
        post_json '/users/1', address: { street: 'Main' }
        expect(last_response).to be_created

        post_json '/users/1', address: { street: 'Main', zip: '1' }
        expect(last_response).to be_bad_request
        expect(last_response.body).to eq('{"error":"address[zip] is not allowed"}')
      end
    end
  end
end
