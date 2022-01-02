# frozen_string_literal: true

describe Grape::Extensions::Hash::ParamBuilder do
  subject { Class.new(Grape::API) }

  def app
    subject
  end

  describe 'in an endpoint' do
    describe '#params' do
      before do
        subject.params do
          build_with Grape::Extensions::Hash::ParamBuilder # rubocop:disable RSpec/DescribedClass
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
      subject.send(:include, Grape::Extensions::Hash::ParamBuilder) # rubocop:disable RSpec/DescribedClass
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
        build_with Grape::Extensions::Hash::ParamBuilder # rubocop:disable RSpec/DescribedClass
        requires :a, type: String
      end

      subject.get '/foo' do
        [params[:a], params['a']]
      end

      get '/foo', a: 'bar'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('["bar", nil]')
    end
  end
end
