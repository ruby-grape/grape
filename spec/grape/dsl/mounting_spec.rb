# frozen_string_literal: true

describe Grape::DSL::Mounting do
  describe '.mount' do
    it 'mounts on a nested path' do
      subject = Class.new(Grape::API)
      app1 = Class.new(Grape::API) do
        get '/' do
          return_no_content
        end
      end
      app2 = Class.new(Grape::API) do
        get '/' do
          return_no_content
        end
      end
      subject.mount app1 => '/app1'
      app1.mount app2 => '/app2'

      env = Rack::MockRequest.env_for('/app1', method: Rack::GET)
      response = Rack::MockResponse[*subject.call(env)]

      expect(response).to be_no_content

      env = Rack::MockRequest.env_for('/app1/app2', method: Rack::GET)
      response = Rack::MockResponse[*subject.call(env)]

      expect(response).to be_no_content
    end

    it 'mounts multiple routes at once' do
      base_app = Class.new(Grape::API)
      app1 = Class.new(Grape::API) do
        get '/' do
          return_no_content
        end
      end
      app2 = Class.new(Grape::API) do
        get '/' do
          return_no_content
        end
      end
      base_app.mount(app1 => '/app1', app2 => '/app2')

      env = Rack::MockRequest.env_for('/app1', method: Rack::GET)
      response = Rack::MockResponse[*base_app.call(env)]

      expect(response).to be_no_content

      env = Rack::MockRequest.env_for('/app2', method: Rack::GET)
      response = Rack::MockResponse[*base_app.call(env)]

      expect(response).to be_no_content
    end
  end
end
