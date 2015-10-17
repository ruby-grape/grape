require 'spec_helper'

module Grape
  describe Routes do
    context 'when without version but with prefix' do
      before do
        class AppApiWithPrefix < Grape::API
          prefix 'v1'

          namespace :user do
            get '/' do
            end
            get '/read' do
            end
          end
        end # class AppApi
      end # before

      describe 'retrieving url helpers' do
        it 'can retrieve v1_index_get_path' do
          expect(Grape::Routes.v1_user_get_path).to eq('/v1/user')
        end

        it 'can retrieve v1_user_read_get_path' do
          expect(Grape::Routes.v1_user_read_get_path).to eq('/v1/user/read')
        end

        it 'can retrieve list of routes' do
          expect(Grape::Routes.all.class).to eq(Array)
          expect(Grape::Routes.all.length).to be > (0)
          expect(Grape::Routes.all.include?('v1_user_get_path')).to be_truthy
        end
      end
    end # context
    context 'when have version' do
      before do
        class AppApiWithVersion < Grape::API
          version 'v1'

          namespace :user do
            get '/read' do
              # do read the data
            end

            post '/create' do
              # do create the data
            end

            get '/delete' do
            end
            post '/delete' do
            end
          end
        end # class AppApi
      end
      describe 'retrieving url helpers' do
        it 'can retrieve user_read_get_path' do
          expect(Grape::Routes.user_read_get_path('v1')).to eq('/v1/user/read')
          expect(Grape::Routes.user_read_get_path('v3')).to eq('/v3/user/read')
        end

        it 'can retrieve user_delete_get_path' do
          expect(Grape::Routes.user_delete_get_path('v1')).to eq('/v1/user/delete')
        end

        it 'can retrieve user_delete_post_path' do
          expect(Grape::Routes.user_delete_post_path('v1')).to eq('/v1/user/delete')
        end

        it 'must have version passed in' do
          expect { Grape::Routes.user_read_get_path }.to raise_error(RuntimeError)
        end
      end
    end
  end
end
