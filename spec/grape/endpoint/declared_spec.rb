# frozen_string_literal: true

describe Grape::Endpoint do
  subject { Class.new(Grape::API) }

  def app
    subject
  end

  describe '#declared' do
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
        optional :empty_set, type: Set
        optional :empty_typed_set, type: Set[String]
      end
    end

    context 'when params are not built with default class' do
      it 'returns an object that corresponds with the params class - hash with indifferent access' do
        subject.params do
          build_with Grape::Extensions::ActiveSupport::HashWithIndifferentAccess::ParamBuilder
        end
        subject.get '/declared' do
          d = declared(params, include_missing: true)
          { declared_class: d.class.to_s }
        end

        get '/declared?first=present'
        expect(JSON.parse(last_response.body)['declared_class']).to eq('ActiveSupport::HashWithIndifferentAccess')
      end

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

      it 'returns an object that corresponds with the params class - hash' do
        subject.params do
          build_with Grape::Extensions::Hash::ParamBuilder
        end
        subject.get '/declared' do
          d = declared(params, include_missing: true)
          { declared_class: d.class.to_s }
        end

        get '/declared?first=present'
        expect(JSON.parse(last_response.body)['declared_class']).to eq('Hash')
      end
    end

    it 'shows nil for nested params if include_missing is true' do
      subject.get '/declared' do
        declared(params, include_missing: true)
      end

      get '/declared?first=present'
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)['nested']['fourth']).to be_nil
    end

    it 'shows nil for multiple allowed types if include_missing is true' do
      subject.get '/declared' do
        declared(params, include_missing: true)
      end

      get '/declared?first=present'
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)['multiple_types']).to be_nil
    end

    it 'does not work in a before filter' do
      subject.before do
        declared(params)
      end
      subject.get('/declared') { declared(params) }

      expect { get('/declared') }.to raise_error(
        Grape::DSL::InsideRoute::MethodNotYetAvailable
      )
    end

    it 'has as many keys as there are declared params' do
      subject.get '/declared' do
        declared(params)
      end
      get '/declared?first=present'
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body).keys.size).to eq(11)
    end

    it 'has a optional param with default value all the time' do
      subject.get '/declared' do
        declared(params)
      end
      get '/declared?first=one'
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)['third']).to eql('third-default')
    end

    it 'builds nested params' do
      subject.get '/declared' do
        declared(params)
      end

      get '/declared?first=present&nested[fourth]=1'
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)['nested'].keys.size).to eq 9
    end

    it 'builds arrays correctly' do
      subject.params do
        requires :first
        optional :second, type: Array
      end
      subject.post('/declared') { declared(params) }

      post '/declared', first: 'present', second: ['present']
      expect(last_response.status).to eq(201)

      body = JSON.parse(last_response.body)
      expect(body['second']).to eq(['present'])
    end

    it 'builds nested params when given array' do
      subject.get '/dummy' do
      end
      subject.params do
        requires :first
        optional :second
        optional :third, default: 'third-default'
        optional :nested, type: Array do
          optional :fourth
        end
      end
      subject.get '/declared' do
        declared(params)
      end

      get '/declared?first=present&nested[][fourth]=1&nested[][fourth]=2'
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)['nested'].size).to eq 2
    end

    context 'when the param is missing and include_missing=false' do
      before do
        subject.get('/declared') { declared(params, include_missing: false) }
      end

      it 'sets nested objects to be nil' do
        get '/declared?first=present'
        expect(last_response.status).to eq(200)
        expect(JSON.parse(last_response.body)['nested']).to be_nil
      end
    end

    context 'when the param is missing and include_missing=true' do
      before do
        subject.get('/declared') { declared(params, include_missing: true) }
      end

      it 'sets objects with type=Hash to be a hash' do
        get '/declared?first=present'
        expect(last_response.status).to eq(200)

        body = JSON.parse(last_response.body)
        expect(body['empty_hash']).to eq({})
        expect(body['nested']).to be_a(Hash)
        expect(body['nested']['empty_hash']).to eq({})
        expect(body['nested']['nested_two']).to be_a(Hash)
      end

      it 'sets objects with type=Set to be a set' do
        get '/declared?first=present'
        expect(last_response.status).to eq(200)

        body = JSON.parse(last_response.body)
        expect(['#<Set: {}>', []]).to include(body['empty_set'])
        expect(['#<Set: {}>', []]).to include(body['empty_typed_set'])
        expect(['#<Set: {}>', []]).to include(body['nested']['empty_set'])
        expect(['#<Set: {}>', []]).to include(body['nested']['empty_typed_set'])
      end

      it 'sets objects with type=Array to be an array' do
        get '/declared?first=present'
        expect(last_response.status).to eq(200)

        body = JSON.parse(last_response.body)
        expect(body['empty_arr']).to eq([])
        expect(body['empty_typed_arr']).to eq([])
        expect(body['arr']).to eq([])
        expect(body['nested']['empty_arr']).to eq([])
        expect(body['nested']['empty_typed_arr']).to eq([])
        expect(body['nested']['nested_arr']).to eq([])
      end

      it 'includes all declared children when type=Hash' do
        get '/declared?first=present'
        expect(last_response.status).to eq(200)

        body = JSON.parse(last_response.body)
        expect(body['nested'].keys).to eq(%w[fourth fifth nested_two nested_arr empty_arr empty_typed_arr empty_hash empty_set empty_typed_set])
        expect(body['nested']['nested_two'].keys).to eq(%w[sixth nested_three])
        expect(body['nested']['nested_two']['nested_three'].keys).to eq(%w[seventh])
      end
    end

    it 'filters out any additional params that are given' do
      subject.get '/declared' do
        declared(params)
      end
      get '/declared?first=one&other=two'
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body).key?(:other)).to be false
    end

    it 'stringifies if that option is passed' do
      subject.get '/declared' do
        declared(params, stringify: true)
      end

      get '/declared?first=one&other=two'
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)['first']).to eq 'one'
    end

    it 'does not include missing attributes if that option is passed' do
      subject.get '/declared' do
        error! 'expected nil', 400 if declared(params, include_missing: false).key?(:second)
        ''
      end

      get '/declared?first=one&other=two'
      expect(last_response.status).to eq(200)
    end

    it 'does not include renamed missing attributes if that option is passed' do
      subject.params do
        optional :renamed_original, as: :renamed
      end
      subject.get '/declared' do
        error! 'expected nil', 400 if declared(params, include_missing: false).key?(:renamed)
        ''
      end

      get '/declared?first=one&other=two'
      expect(last_response.status).to eq(200)
    end

    it 'includes attributes with value that evaluates to false' do
      subject.params do
        requires :first
        optional :boolean
      end

      subject.post '/declared' do
        error!('expected false', 400) if declared(params, include_missing: false)[:boolean] != false
        ''
      end

      post '/declared', ::Grape::Json.dump(first: 'one', boolean: false), 'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to eq(201)
    end

    it 'includes attributes with value that evaluates to nil' do
      subject.params do
        requires :first
        optional :second
      end

      subject.post '/declared' do
        error!('expected nil', 400) unless declared(params, include_missing: false)[:second].nil?
        ''
      end

      post '/declared', ::Grape::Json.dump(first: 'one', second: nil), 'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to eq(201)
    end

    it 'includes missing attributes with defaults when there are nested hashes' do
      subject.get '/dummy' do
      end

      subject.params do
        requires :first
        optional :second
        optional :third, default: nil
        optional :nested, type: Hash do
          optional :fourth, default: nil
          optional :fifth, default: nil
          requires :nested_nested, type: Hash do
            optional :sixth, default: 'sixth-default'
            optional :seven, default: nil
          end
        end
      end

      subject.get '/declared' do
        declared(params, include_missing: false)
      end

      get '/declared?first=present&nested[fourth]=&nested[nested_nested][sixth]=sixth'
      json = JSON.parse(last_response.body)
      expect(last_response.status).to eq(200)
      expect(json['first']).to eq 'present'
      expect(json['nested'].keys).to eq %w[fourth fifth nested_nested]
      expect(json['nested']['fourth']).to eq ''
      expect(json['nested']['nested_nested'].keys).to eq %w[sixth seven]
      expect(json['nested']['nested_nested']['sixth']).to eq 'sixth'
    end

    it 'does not include missing attributes when there are nested hashes' do
      subject.get '/dummy' do
      end

      subject.params do
        requires :first
        optional :second
        optional :third
        optional :nested, type: Hash do
          optional :fourth
          optional :fifth
        end
      end

      subject.get '/declared' do
        declared(params, include_missing: false)
      end

      get '/declared?first=present&nested[fourth]=4'
      json = JSON.parse(last_response.body)
      expect(last_response.status).to eq(200)
      expect(json['first']).to eq 'present'
      expect(json['nested'].keys).to eq %w[fourth]
      expect(json['nested']['fourth']).to eq '4'
    end
  end

  describe '#declared; call from child namespace' do
    before do
      subject.format :json
      subject.namespace :parent do
        params do
          requires :parent_name, type: String
        end

        namespace ':parent_name' do
          params do
            requires :child_name, type: String
            requires :child_age, type: Integer
          end

          namespace ':child_name' do
            params do
              requires :grandchild_name, type: String
            end

            get ':grandchild_name' do
              {
                'params' => params,
                'without_parent_namespaces' => declared(params, include_parent_namespaces: false),
                'with_parent_namespaces' => declared(params, include_parent_namespaces: true)
              }
            end
          end
        end
      end

      get '/parent/foo/bar/baz', child_age: 5, extra: 'hello'
    end

    let(:parsed_response) { JSON.parse(last_response.body, symbolize_names: true) }

    it { expect(last_response.status).to eq 200 }

    context 'with include_parent_namespaces: false' do
      it 'returns declared parameters only from current namespace' do
        expect(parsed_response[:without_parent_namespaces]).to eq(
          grandchild_name: 'baz'
        )
      end
    end

    context 'with include_parent_namespaces: true' do
      it 'returns declared parameters from every parent namespace' do
        expect(parsed_response[:with_parent_namespaces]).to eq(
          parent_name: 'foo',
          child_name: 'bar',
          grandchild_name: 'baz',
          child_age: 5
        )
      end
    end

    context 'without declaration' do
      it 'returns all requested parameters' do
        expect(parsed_response[:params]).to eq(
          parent_name: 'foo',
          child_name: 'bar',
          grandchild_name: 'baz',
          child_age: 5,
          extra: 'hello'
        )
      end
    end
  end

  describe '#declared; from a nested mounted endpoint' do
    before do
      doubly_mounted = Class.new(Grape::API)
      doubly_mounted.namespace :more do
        params do
          requires :y, type: Integer
        end
        route_param :y do
          get do
            {
              params: params,
              declared_params: declared(params)
            }
          end
        end
      end

      mounted = Class.new(Grape::API)
      mounted.namespace :another do
        params do
          requires :mount_space, type: Integer
        end
        route_param :mount_space do
          mount doubly_mounted
        end
      end

      subject.format :json
      subject.namespace :something do
        params do
          requires :id, type: Integer
        end
        resource ':id' do
          mount mounted
        end
      end
    end

    it 'can access parent attributes' do
      get '/something/123/another/456/more/789'
      expect(last_response.status).to eq 200
      json = JSON.parse(last_response.body, symbolize_names: true)

      # test all three levels of params
      expect(json[:declared_params][:y]).to eq 789
      expect(json[:declared_params][:mount_space]).to eq 456
      expect(json[:declared_params][:id]).to eq 123
    end
  end

  describe '#declared; mixed nesting' do
    before do
      subject.format :json
      subject.resource :users do
        route_param :id, type: Integer, desc: 'ID desc' do
          # Adding this causes route_setting(:declared_params) to be nil for the
          # get block in namespace 'foo' below
          get do
          end

          namespace 'foo' do
            get do
              {
                params: params,
                declared_params: declared(params),
                declared_params_no_parent: declared(params, include_parent_namespaces: false)
              }
            end
          end
        end
      end
    end

    it 'can access parent route_param' do
      get '/users/123/foo', bar: 'bar'
      expect(last_response.status).to eq 200
      json = JSON.parse(last_response.body, symbolize_names: true)

      expect(json[:declared_params][:id]).to eq 123
      expect(json[:declared_params_no_parent][:id]).to be_nil
    end
  end

  describe '#declared; with multiple route_param' do
    before do
      mounted = Class.new(Grape::API)
      mounted.namespace :albums do
        get do
          declared(params)
        end
      end

      subject.format :json
      subject.namespace :artists do
        route_param :id, type: Integer do
          get do
            declared(params)
          end

          params do
            requires :filter, type: String
          end
          get :some_route do
            declared(params)
          end
        end

        route_param :artist_id, type: Integer do
          namespace :compositions do
            get do
              declared(params)
            end
          end
        end

        route_param :compositor_id, type: Integer do
          mount mounted
        end
      end
    end

    it 'return only :id without :artist_id' do
      get '/artists/1'
      json = JSON.parse(last_response.body, symbolize_names: true)

      expect(json).to be_key(:id)
      expect(json).not_to be_key(:artist_id)
    end

    it 'return only :artist_id without :id' do
      get '/artists/1/compositions'
      json = JSON.parse(last_response.body, symbolize_names: true)

      expect(json).to be_key(:artist_id)
      expect(json).not_to be_key(:id)
    end

    it 'return :filter and :id parameters in declared for second enpoint inside route_param' do
      get '/artists/1/some_route', filter: 'some_filter'
      json = JSON.parse(last_response.body, symbolize_names: true)

      expect(json).to be_key(:filter)
      expect(json).to be_key(:id)
      expect(json).not_to be_key(:artist_id)
    end

    it 'return :compositor_id for mounter in route_param' do
      get '/artists/1/albums'
      json = JSON.parse(last_response.body, symbolize_names: true)

      expect(json).to be_key(:compositor_id)
      expect(json).not_to be_key(:id)
      expect(json).not_to be_key(:artist_id)
    end
  end

  describe 'parameter renaming' do
    context 'with a deeply nested parameter structure' do
      let(:params) do
        {
          i_a: 'a',
          i_b: {
            i_c: 'c',
            i_d: {
              i_e: {
                i_f: 'f',
                i_g: 'g',
                i_h: [
                  {
                    i_ha: 'ha1',
                    i_hb: {
                      i_hc: 'c'
                    }
                  },
                  {
                    i_ha: 'ha2',
                    i_hb: {
                      i_hc: 'c'
                    }
                  }
                ]
              }
            }
          }
        }
      end
      let(:declared) do
        {
          o_a: 'a',
          o_b: {
            o_c: 'c',
            o_d: {
              o_e: {
                o_f: 'f',
                o_g: 'g',
                o_h: [
                  {
                    o_ha: 'ha1',
                    o_hb: {
                      o_hc: 'c'
                    }
                  },
                  {
                    o_ha: 'ha2',
                    o_hb: {
                      o_hc: 'c'
                    }
                  }
                ]
              }
            }
          }
        }
      end
      let(:params_keys) do
        [
          'i_a',
          'i_b',
          'i_b[i_c]',
          'i_b[i_d]',
          'i_b[i_d][i_e]',
          'i_b[i_d][i_e][i_f]',
          'i_b[i_d][i_e][i_g]',
          'i_b[i_d][i_e][i_h]',
          'i_b[i_d][i_e][i_h][i_ha]',
          'i_b[i_d][i_e][i_h][i_hb]',
          'i_b[i_d][i_e][i_h][i_hb][i_hc]'
        ]
      end

      before do
        subject.format :json
        subject.params do
          optional :i_a, type: String, as: :o_a
          optional :i_b, type: Hash, as: :o_b do
            optional :i_c, type: String, as: :o_c
            optional :i_d, type: Hash, as: :o_d do
              optional :i_e, type: Hash, as: :o_e do
                optional :i_f, type: String, as: :o_f
                optional :i_g, type: String, as: :o_g
                optional :i_h, type: Array, as: :o_h do
                  optional :i_ha, type: String, as: :o_ha
                  optional :i_hb, type: Hash, as: :o_hb do
                    optional :i_hc, type: String, as: :o_hc
                  end
                end
              end
            end
          end
        end
        subject.post '/test' do
          declared(params, include_missing: false)
        end
        subject.post '/test/no-mod' do
          before = params.to_h
          declared(params, include_missing: false)
          after = params.to_h
          { before: before, after: after }
        end
      end

      it 'generates the correct parameter names for documentation' do
        expect(subject.routes.first.params.keys).to match(params_keys)
      end

      it 'maps the renamed parameter correctly' do
        post '/test', **params
        expect(JSON.parse(last_response.body, symbolize_names: true)).to \
          match(declared)
      end

      it 'maps no parameters when none are given' do
        post '/test'
        expect(JSON.parse(last_response.body)).to match({})
      end

      it 'does not modify the request params' do
        post '/test/no-mod', **params
        result = JSON.parse(last_response.body, symbolize_names: true)
        expect(result[:before]).to match(result[:after])
      end
    end

    context 'with a renamed root parameter' do
      before do
        subject.format :json
        subject.params do
          optional :email_address, type: String, regexp: /.+@.+/, as: :email
        end
        subject.post '/test' do
          declared(params, include_missing: false)
        end
      end

      it 'generates the correct parameter names for documentation' do
        expect(subject.routes.first.params.keys).to match(%w[email_address])
      end

      it 'maps the renamed parameter correctly (original name)' do
        post '/test', email_address: 'test@example.com'
        expect(JSON.parse(last_response.body)).to \
          match('email' => 'test@example.com')
      end

      it 'validates the renamed parameter correctly (original name)' do
        post '/test', email_address: 'bad[at]example.com'
        expect(JSON.parse(last_response.body)).to \
          match('error' => 'email_address is invalid')
      end

      it 'ignores the renamed parameter (as name)' do
        post '/test', email: 'test@example.com'
        expect(JSON.parse(last_response.body)).to match({})
      end
    end

    context 'with a renamed hash with nested parameters' do
      before do
        subject.format :json
        subject.params do
          optional :address, type: Hash, as: :address_attributes do
            optional :street, type: String, values: ['Street 1', 'Street 2'],
                              default: 'Street 1'
            optional :city, type: String
          end
        end
        subject.post '/test' do
          declared(params, include_missing: false)
        end
      end

      it 'generates the correct parameter names for documentation' do
        expect(subject.routes.first.params.keys).to \
          match(%w[address address[street] address[city]])
      end

      it 'maps the renamed parameter correctly (original name)' do
        post '/test', address: { city: 'Berlin', street: 'Street 2', t: 't' }
        expect(JSON.parse(last_response.body)).to \
          match('address_attributes' => { 'city' => 'Berlin',
                                          'street' => 'Street 2' })
      end

      it 'validates the renamed parameter correctly (original name)' do
        post '/test', address: { street: 'unknown' }
        expect(JSON.parse(last_response.body)).to \
          match('error' => 'address[street] does not have a valid value')
      end

      it 'ignores the renamed parameter (as name)' do
        post '/test', address_attributes: { city: 'Berlin', unknown: '1' }
        expect(JSON.parse(last_response.body)).to match({})
      end
    end

    context 'with a renamed hash with nested renamed parameter' do
      before do
        subject.format :json
        subject.params do
          optional :user, type: Hash, as: :user_attributes do
            optional :email_address, type: String, regexp: /.+@.+/, as: :email
          end
        end
        subject.post '/test' do
          declared(params, include_missing: false)
        end
      end

      it 'generates the correct parameter names for documentation' do
        expect(subject.routes.first.params.keys).to \
          match(%w[user user[email_address]])
      end

      it 'maps the renamed parameter correctly (original name)' do
        post '/test', user: { email_address: 'test@example.com' }
        expect(JSON.parse(last_response.body)).to \
          match('user_attributes' => { 'email' => 'test@example.com' })
      end

      it 'validates the renamed parameter correctly (original name)' do
        post '/test', user: { email_address: 'bad[at]example.com' }
        expect(JSON.parse(last_response.body)).to \
          match('error' => 'user[email_address] is invalid')
      end

      it 'ignores the renamed parameter (as name, 1)' do
        post '/test', user: { email: 'test@example.com' }
        expect(JSON.parse(last_response.body)).to \
          match({ 'user_attributes' => {} })
      end

      it 'ignores the renamed parameter (as name, 2)' do
        post '/test', user_attributes: { email_address: 'test@example.com' }
        expect(JSON.parse(last_response.body)).to match({})
      end

      it 'ignores the renamed parameter (as name, 3)' do
        post '/test', user_attributes: { email: 'test@example.com' }
        expect(JSON.parse(last_response.body)).to match({})
      end
    end
  end
end
