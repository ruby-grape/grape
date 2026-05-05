# frozen_string_literal: true

describe Grape::Middleware::Error do
  let(:err_app) do
    Class.new do
      class << self
        attr_accessor :error, :format

        def call(_env)
          throw :error, error
        end
      end
    end
  end
  let(:options) { { default_message: 'Aww, hamburgers.' } }

  let(:app) do
    opts = options
    context = self
    Rack::Builder.app do
      use Spec::Support::EndpointFaker
      use Grape::Middleware::Error, **opts # rubocop:disable RSpec/DescribedClass
      run context.err_app
    end
  end

  it 'sets the status code appropriately' do
    err_app.error = { status: 410 }
    get '/'
    expect(last_response.status).to eq(410)
  end

  it 'sets the status code based on the rack util status code symbol' do
    err_app.error = { status: :gone }
    get '/'
    expect(last_response.status).to eq(410)
  end

  it 'sets the error message appropriately' do
    err_app.error = { message: 'Awesome stuff.' }
    get '/'
    expect(last_response.body).to eq('Awesome stuff.')
  end

  it 'defaults to a 500 status' do
    err_app.error = {}
    get '/'
    expect(last_response).to be_server_error
  end

  it 'has a default message' do
    err_app.error = {}
    get '/'
    expect(last_response.body).to eq('Aww, hamburgers.')
  end

  context 'with http code' do
    let(:options) {  { default_message: 'Aww, hamburgers.' } }

    it 'adds the status code if wanted' do
      err_app.error = { message: { code: 200 } }
      get '/'

      expect(last_response.body).to eq({ code: 200 }.to_json)
    end
  end

  context 'when a rescue handler returns a Hash with :message, :status, :headers' do
    let(:raising_app) do
      Class.new do
        def self.call(_env)
          raise StandardError, 'boom'
        end
      end
    end

    let(:options) do
      {
        rescue_handlers: {
          StandardError => -> { { message: 'oops', status: 500, headers: {} } }
        }
      }
    end

    let(:app) do
      opts = options
      context = self
      Rack::Builder.app do
        use Spec::Support::EndpointFaker
        use Grape::Middleware::Error, **opts # rubocop:disable RSpec/DescribedClass
        run context.raising_app
      end
    end

    it 'emits a deprecation warning' do
      expect { get '/' }.to raise_error(
        ActiveSupport::DeprecationException, /rescue handler is deprecated/
      )
    end
  end
end
