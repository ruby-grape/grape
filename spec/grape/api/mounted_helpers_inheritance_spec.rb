# frozen_string_literal: true

describe Grape::API do
  context 'when mounting a child API that inherits helpers from parent API' do
    let(:child_api) do
      Class.new(Grape::API) do
        get '/test' do
          parent_helper
        end
      end
    end

    let(:parent_api) do
      context = self
      Class.new(Grape::API) do
        helpers do
          def parent_helper
            'parent helper value'
          end
        end

        mount context.child_api
      end
    end

    def app
      parent_api
    end

    it 'inherits helpers from parent API to mounted child API' do
      get '/test'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('parent helper value')
    end
  end
end
