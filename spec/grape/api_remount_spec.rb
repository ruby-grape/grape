require 'spec_helper'
require 'shared/versioning_examples'

describe Grape::API do
  subject(:a_remounted_api) { Class.new(Grape::API) }
  let(:root_api) { Class.new(Grape::API) }

  def app
    root_api
  end

  describe 'remounting an API' do
    context 'with a defined route' do
      before do
        a_remounted_api.get '/votes' do
          '10 votes'
        end
      end

      context 'when mounting one instance' do
        before do
          root_api.mount a_remounted_api
        end

        it 'can access the endpoint' do
          get '/votes'
          expect(last_response.body).to eql '10 votes'
        end
      end

      context 'when mounting twice' do
        before do
          root_api.mount a_remounted_api => '/posts'
          root_api.mount a_remounted_api => '/comments'
        end

        it 'can access the votes in both places' do
          get '/posts/votes'
          expect(last_response.body).to eql '10 votes'
          get '/comments/votes'
          expect(last_response.body).to eql '10 votes'
        end
      end

      context 'when mounting on namespace' do
        before do
          stub_const('StaticRefToAPI', a_remounted_api)
          root_api.namespace 'posts' do
            mount StaticRefToAPI
          end

          root_api.namespace 'comments' do
            mount StaticRefToAPI
          end
        end

        it 'can access the votes in both places' do
          get '/posts/votes'
          expect(last_response.body).to eql '10 votes'
          get '/comments/votes'
          expect(last_response.body).to eql '10 votes'
        end
      end
    end

    context 'with a dynamically configured route' do
      before do
        a_remounted_api.namespace 'api' do
          get "/#{configuration[:path]}" do
            '10 votes'
          end
        end
        root_api.mount a_remounted_api, with: { path: 'votes' }
        root_api.mount a_remounted_api, with: { path: 'scores' }
      end

      it 'will use the dynamic configuration on all routes' do
        get 'api/votes'
        expect(last_response.body).to eql '10 votes'
        get 'api/scores'
        expect(last_response.body).to eql '10 votes'
      end
    end
  end
end
