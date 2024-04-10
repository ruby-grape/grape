# frozen_string_literal: true

describe Grape::Extensions::Hashie::Mash::ParamBuilder do
  subject { Class.new(Grape::API) }

  def app
    subject
  end

  describe 'in an endpoint' do
    describe '#params' do
      before do
        subject.params do
          build_with Grape::Extensions::Hashie::Mash::ParamBuilder # rubocop:disable RSpec/DescribedClass
        end

        subject.get do
          params.class
        end
      end

      it 'is of type Hashie::Mash' do
        get '/'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('Hashie::Mash')
      end
    end
  end

  describe 'in an api' do
    before do
      subject.send(:include, Grape::Extensions::Hashie::Mash::ParamBuilder) # rubocop:disable RSpec/DescribedClass
    end

    describe '#params' do
      before do
        subject.get do
          params.class
        end
      end

      it 'is Hashie::Mash' do
        get '/'
        expect(last_response.status).to eq(200)
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
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('Hashie::Mash')
      end
    end

    it 'is indifferent to key or symbol access' do
      subject.params do
        build_with Grape::Extensions::Hashie::Mash::ParamBuilder # rubocop:disable RSpec/DescribedClass
        requires :a, type: String
      end
      subject.get '/foo' do
        [params[:a], params['a']]
      end

      get '/foo', a: 'bar'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('["bar", "bar"]')
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
          build_with Grape::Extensions::Hashie::Mash::ParamBuilder # rubocop:disable RSpec/DescribedClass
          requires :foo, type: String
        end
        route_param :foo do
          get do
            [params[:foo], params['foo']]
          end
        end
      end

      get '/route_param/bar', foo: 'baz'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('["bar", "bar"]')
    end
  end
end
