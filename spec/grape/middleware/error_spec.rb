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

  describe 'when a rescue_from block raises' do
    subject(:response) do
      get '/'
      last_response
    end

    context 'and the re-raised exception has a registered rescue_from' do
      let(:app) do
        Class.new(Grape::API) do
          format :txt

          custom_error_class = Class.new(StandardError)
          const_set(:CustomError, custom_error_class)

          rescue_from custom_error_class do |e|
            error!("custom-handled: #{e.message}", 422)
          end

          rescue_from :all do |e|
            raise custom_error_class, "wrapped(#{e.message})"
          end

          get('/') { raise ArgumentError, 'oops' }
        end
      end

      it 'redispatches to the registered handler' do
        expect(response.status).to eq(422)
        expect(response.body).to eq('custom-handled: wrapped(oops)')
      end
    end

    context 'and the re-raised exception is a Grape::Exceptions::Base subclass' do
      let(:app) do
        Class.new(Grape::API) do
          format :txt

          teapot_class = Class.new(Grape::Exceptions::Base) do
            def initialize
              super(status: 418, message: 'teapot')
            end
          end
          const_set(:TeapotError, teapot_class)

          rescue_from :all do
            raise teapot_class
          end

          get('/') { raise StandardError, 'first' }
        end
      end

      it 'renders the exception via the default Grape error path with its own status' do
        expect(response.status).to eq(418)
        expect(response.body).to eq('teapot')
      end
    end

    context 'and the re-raised exception is an unrecognised StandardError' do
      let(:app) do
        Class.new(Grape::API) do
          format :txt

          rescue_from :all do
            raise NoMethodError, "undefined method 'foo' for nil"
          end

          get('/') { raise StandardError, 'first' }
        end
      end

      it 'renders the generic Internal Server Error response' do
        expect(response.status).to eq(500)
        expect(response.body).to eq('Internal Server Error')
      end

      it "exposes the original exception via env['grape.exception']" do
        captured = nil
        original_call = app.method(:call)
        allow(app).to receive(:call) do |env|
          result = original_call.call(env)
          captured = env[Grape::Env::GRAPE_EXCEPTION]
          result
        end

        response

        expect(captured).to be_a(NoMethodError)
        expect(captured.message).to include("undefined method 'foo'")
      end
    end

    context 'and a redispatched handler also raises' do
      let(:app) do
        Class.new(Grape::API) do
          format :txt

          inner_class = Class.new(StandardError)
          outer_class = Class.new(StandardError)
          const_set(:InnerError, inner_class)
          const_set(:OuterError, outer_class)

          rescue_from inner_class do
            raise outer_class, 'second-level'
          end

          rescue_from outer_class do |e|
            error!("would-handle: #{e.message}", 422)
          end

          rescue_from :all do
            raise inner_class, 'first-level'
          end

          get('/') { raise StandardError, 'route' }
        end
      end

      it 'stops at the safe default after one redispatch' do
        expect(response.status).to eq(500)
        expect(response.body).to eq('Internal Server Error')
      end
    end

    context 'and the user has opted into rescue_from :internal_grape_exceptions' do
      let(:app) do
        Class.new(Grape::API) do
          format :txt

          rescue_from :internal_grape_exceptions do |e|
            error!("internal: #{e.class}: #{e.message}", 503)
          end

          rescue_from :all do
            raise NoMethodError, "undefined method 'foo' for nil"
          end

          get('/') { raise StandardError, 'first' }
        end
      end

      it 'invokes the user handler with the original exception' do
        expect(response.status).to eq(503)
        expect(response.body).to eq("internal: NoMethodError: undefined method 'foo' for nil")
      end

      it "still exposes the original exception via env['grape.exception']" do
        captured = nil
        original_call = app.method(:call)
        allow(app).to receive(:call) do |env|
          result = original_call.call(env)
          captured = env[Grape::Env::GRAPE_EXCEPTION]
          result
        end

        response

        expect(captured).to be_a(NoMethodError)
      end

      context 'and the user handler also raises' do
        let(:app) do
          Class.new(Grape::API) do
            format :txt

            rescue_from :internal_grape_exceptions do
              raise 'handler bug'
            end

            rescue_from :all do
              raise NoMethodError, 'first internal'
            end

            get('/') { raise StandardError, 'route' }
          end
        end

        it 'falls through to the framework safe default (loop bounded)' do
          expect(response.status).to eq(500)
          expect(response.body).to eq('Internal Server Error')
        end
      end
    end

    context 'and the handler returns a non-Response, non-error value' do
      let(:app) do
        Class.new(Grape::API) do
          format :txt

          rescue_from :all do
            'not a Rack response'
          end

          get('/') { raise StandardError, 'boom' }
        end
      end

      it 'falls through to the InvalidResponse path (existing behaviour preserved)' do
        expect(response.status).to eq(500)
        expect(response.body).to eq('Invalid response')
      end
    end
  end
end
