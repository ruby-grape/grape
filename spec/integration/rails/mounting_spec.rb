# frozen_string_literal: true

describe 'Rails', if: defined?(Rails) do
  context 'rails mounted' do
    let(:app) do
      require 'rails'
      require 'action_controller/railtie'

      api = Class.new(Grape::API) do
        get('/test_grape') { 'rails mounted' }
      end

      Class.new(Rails::Application) do
        config.eager_load = false
        config.load_defaults "#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}"
        config.api_only = true
        config.consider_all_requests_local = true
        config.hosts << 'example.org'

        routes.append do
          mount api => '/'

          get 'up', to: lambda { |_env|
            ['200', {}, ['hello world']]
          }
        end
      end
    end

    before { app.initialize! }

    it 'responds' do
      get '/test_grape'
      expect(last_response).to be_successful
      expect(last_response.body).to eq('rails mounted')
      get '/up'
      expect(last_response).to be_successful
      expect(last_response.body).to eq('hello world')
    end
  end
end
