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

    describe 'params declared with String names' do
      it 'finds a required one' do
        subject.params do
          requires 'a'
        end
        subject.get('/foo') { params[:a] }

        get '/foo', a: 'bar'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('bar')
      end

      it 'validates an optional one' do
        subject.params do
          optional 'a', type: Integer
        end
        subject.get('/foo') { params[:a].inspect }

        get '/foo', a: 'x'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('a is invalid')
      end

      it 'declares their values' do
        subject.params do
          optional 'a', type: Integer
        end
        subject.get('/foo') { declared(params).inspect }

        get '/foo', a: '1'
        expect(last_response.body).to eq({ a: 1 }.inspect)
      end

      it 'finds the params of a Hash scope' do
        subject.params do
          requires 'a', type: Hash do
            requires 'b'
          end
        end
        subject.get('/foo') { params[:a][:b] }

        get '/foo', a: { b: 'bar' }
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('bar')
      end

      it 'finds the params of an Array scope' do
        subject.params do
          requires 'items', type: Array do
            requires 'b'
          end
        end
        subject.get('/foo') { params[:items].map { |item| item[:b] }.join(',') }

        get '/foo', items: [{ b: 'x' }, { b: 'y' }]
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('x,y')
      end

      it 'validates the params under a given' do
        subject.params do
          optional 'a'
          given 'a' => ->(val) { val == 'x' } do
            requires 'b'
          end
        end
        subject.get('/foo') { 'ok' }

        get '/foo', a: 'x'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('b is missing')
      end

      it 'compares the param a same_as names' do
        subject.params do
          optional 'a'
          optional 'b', same_as: 'a'
        end
        subject.get('/foo') { 'ok' }

        get '/foo', a: 'x', b: 'x'
        expect(last_response.status).to eq(200)

        get '/foo', a: 'x', b: 'y'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('b is not the same as a')
      end
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
