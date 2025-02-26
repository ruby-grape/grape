# frozen_string_literal: true

describe Grape::ParamsBuilder::Hash do
  subject { app }

  let(:app) do
    Class.new(Grape::API)
  end

  describe 'in an endpoint' do
    describe '#params' do
      before do
        subject.params do
          build_with :hash
        end

        subject.get do
          params.class
        end
      end

      it 'is of type Hash' do
        get '/'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('Hash')
      end
    end
  end

  describe 'in an api' do
    before do
      subject.build_with :hash
    end

    describe '#params' do
      before do
        subject.get do
          params.class
        end
      end

      it 'is Hash' do
        get '/'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('Hash')
      end
    end

    it 'symbolizes params keys' do
      subject.params do
        optional :a, type: Hash do
          optional :b, type: Hash do
            optional :c, type: String
          end
          optional :d, type: Array
        end
      end

      subject.get '/foo' do
        [params[:a][:b][:c], params[:a][:d]]
      end

      get '/foo', 'a' => { b: { c: 'bar' }, 'd' => ['foo'] }
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('["bar", ["foo"]]')
    end

    it 'symbolizes the params' do
      subject.params do
        build_with :hash
        requires :a, type: String
      end

      subject.get '/foo' do
        [params[:a], params['a']]
      end

      get '/foo', a: 'bar'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('["bar", nil]')
    end

    it 'does not overwrite route_param with a regular param if they have same name' do
      subject.namespace :route_param do
        route_param :foo do
          get { params.to_json }
        end
      end

      get '/route_param/bar', foo: 'baz'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('{"foo":"bar"}')
    end

    it 'does not overwrite route_param with a defined regular param if they have same name' do
      subject.namespace :route_param do
        params do
          requires :foo, type: String
        end
        route_param :foo do
          get do
            params[:foo]
          end
        end
      end

      get '/route_param/bar', foo: 'baz'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('bar')
    end
  end
end
