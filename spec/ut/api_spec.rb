require 'spec_helper'

describe Grape::API do
  subject {
    Class.new(Grape::API) do |variable|
      rescue_from :all
    end
  }

  let(:v1_app) {
    Class.new(Grape::API) do
      version 'v1', using: :header, vendor: 'test'
      resources :users do
        get :hello do
          'one'
        end
      end
    end
  }

  let(:v2_app) {
    Class.new(Grape::API) do
      version 'v2', using: :header, vendor: 'test'
      resources :users do
        get :hello do
          'two'
        end
      end
    end
  }

  def app
    subject.mount v1_app
    subject.mount v2_app
    subject
  end

  context "with header versioned endpoints and a rescue_all block defined" do
    it 'responds correctly to a v1 request' do
      versioned_get '/users/hello', 'v1', using: :header, vendor: 'test'
      expect(last_response.body).to eq('one')
      expect(last_response.body).not_to include('API vendor or version not found')
    end

    it 'responds correctly to a v2 request' do
      versioned_get '/users/hello', 'v2', using: :header, vendor: 'test'
      expect(last_response.body).to eq('two')
      expect(last_response.body).not_to include('API vendor or version not found')
    end
  end

end
