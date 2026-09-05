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

  context 'when a rescue handler returns a Hash that looks like an error response' do
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

    # A Hash used to be accepted as an error response. It no longer is: a
    # handler says what it means with `error!` or a Grape::Exceptions::ErrorResponse,
    # and anything else is an invalid response rather than a guess at one.
    it 'answers with an invalid response rather than reading the Hash' do
      get '/'

      expect(last_response.status).to eq(500)
      expect(last_response.body).not_to include('oops')
    end
  end

  # Rendering happens inside #call!'s rescue clause, so it is not covered by
  # that rescue: without a failsafe an error formatter that raises takes the
  # exception straight out through every middleware above.
  describe 'when the error response cannot be rendered' do
    subject(:response) do
      get '/'
      last_response
    end

    context 'and the formatter chokes on the payload' do
      let(:app) do
        Class.new(Grape::API) do
          format :json

          rescue_from(:all) { |e| error!({ detail: e.message }, 404) }

          # A message the JSON formatter cannot serialize.
          get('/') { raise StandardError, +"bad \xC3 byte".b }
        end
      end

      it 'answers with the framework message in the API format' do
        expect(response.status).to eq(500)
        expect(response.headers[Rack::CONTENT_TYPE]).to include('application/json')
        expect(JSON.parse(response.body)).to eq('error' => 'Internal Server Error')
      end

      it 'exposes the rendering failure on the rack env' do
        get '/'
        expect(last_request.env[Grape::Env::GRAPE_EXCEPTION]).to be_a(StandardError)
      end

      # The key error trackers read to find an exception that never propagated;
      # grape.exception alone leaves a swallowed failure invisible to them.
      it 'exposes the rendering failure under rack.exception' do
        get '/'
        expect(last_request.env[Grape::Env::RACK_EXCEPTION]).to be(last_request.env[Grape::Env::GRAPE_EXCEPTION])
      end

      it 'writes the rendering failure to rack.errors' do
        errors = StringIO.new
        get '/', {}, Rack::RACK_ERRORS => errors
        expect(errors.string).to include('Grape could not render the error response: JSON::GeneratorError')
      end
    end

    context 'and the formatter is broken outright' do
      let(:app) do
        Class.new(Grape::API) do
          format :json

          error_formatter :json, ->(**) { raise 'formatter is broken' }
          rescue_from(:all) { error!({ detail: 'nope' }, 404) }

          get('/') { raise StandardError, 'boom' }
        end
      end

      it 'drops the formatter rather than recursing' do
        expect(response.status).to eq(500)
        expect(response.headers[Rack::CONTENT_TYPE]).to include('text/plain')
        expect(response.body).to eq('500 Internal Server Error')
      end
    end

    context 'and nothing rescues the original exception' do
      let(:app) do
        Class.new(Grape::API) do
          format :json

          get('/') { raise ArgumentError, 'kaboom' }
        end
      end

      it 'keeps propagating it' do
        expect { get '/' }.to raise_error(ArgumentError, 'kaboom')
      end
    end

    context 'and Grape.config.raise_rendering_errors is set' do
      let(:app) do
        Class.new(Grape::API) do
          format :json

          rescue_from(:all) { |e| error!({ detail: e.message }, 404) }

          get('/') { raise StandardError, +"bad \xC3 byte".b }
        end
      end

      around do |example|
        Grape.config.raise_rendering_errors = true
        example.run
      ensure
        Grape.config.raise_rendering_errors = false
      end

      it 'lets the rendering failure propagate as it did before the failsafe' do
        expect { get '/' }.to raise_error(JSON::GeneratorError)
      end
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

      # grape.exception is Grape's own key, which no error tracker reads. This
      # path answers 500 rather than letting the exception propagate, so without
      # rack.exception a tracker above Grape never learns it happened.
      it "exposes the original exception via env['rack.exception']" do
        captured = nil
        original_call = app.method(:call)
        allow(app).to receive(:call) do |env|
          result = original_call.call(env)
          captured = env[Grape::Env::RACK_EXCEPTION]
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

  describe '#error!' do
    it 'sets the status and renders a formatted error response' do
      env = Rack::MockRequest.env_for('/')
      endpoint = Spec::Support::EndpointFaker::FakerAPI.endpoints.first
      env[Grape::Env::API_ENDPOINT] = endpoint
      middleware = described_class.new(->(_env) {})
      middleware.instance_variable_set(:@env, env)

      expect(endpoint).to receive(:status).with(422)
      response = middleware.__send__(:error!, 'failure', 422)
      expect(response.status).to eq(422)
      expect(response.body).to eq(['failure'])
    end
  end

  describe '#error?' do
    subject(:middleware) { described_class.new(->(_env) {}) }

    it 'returns true for a Grape::Exceptions::ErrorResponse' do
      response = Grape::Exceptions::ErrorResponse.new(message: 'oops', status: 500, headers: {})
      expect(middleware.__send__(:error?, response)).to be true
    end

    it 'returns false for any other object' do
      expect(middleware.__send__(:error?, 'not an error')).to be false
    end
  end
end
