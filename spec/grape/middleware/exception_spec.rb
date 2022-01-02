# frozen_string_literal: true

describe Grape::Middleware::Error do
  let(:exception_app) do
    Class.new do
      class << self
        def call(_env)
          raise 'rain!'
        end
      end
    end
  end

  let(:other_exception_app) do
    Class.new do
      class << self
        def call(_env)
          raise NotImplementedError, 'snow!'
        end
      end
    end
  end

  let(:custom_error_app) do
    Class.new do
      class << self
        class CustomError < Grape::Exceptions::Base; end

        def call(_env)
          raise CustomError.new(status: 400, message: 'failed validation')
        end
      end
    end
  end

  let(:error_hash_app) do
    Class.new do
      class << self
        def error!(message, status)
          throw :error, message: { error: message, detail: 'missing widget' }, status: status
        end

        def call(_env)
          error!('rain!', 401)
        end
      end
    end
  end

  let(:access_denied_app) do
    Class.new do
      class << self
        def error!(message, status)
          throw :error, message: message, status: status
        end

        def call(_env)
          error!('Access Denied', 401)
        end
      end
    end
  end

  let(:app) do
    builder = Rack::Builder.new
    builder.use Spec::Support::EndpointFaker
    if options.any?
      builder.use described_class, options
    else
      builder.use described_class
    end
    builder.run running_app
    builder.to_app
  end

  context 'with defaults' do
    let(:running_app) { exception_app }
    let(:options) { {} }

    it 'does not trap errors by default' do
      expect { get '/' }.to raise_error(RuntimeError, 'rain!')
    end
  end

  context 'with rescue_all' do
    context 'StandardError exception' do
      let(:running_app) { exception_app }
      let(:options) { { rescue_all: true } }

      it 'sets the message appropriately' do
        get '/'
        expect(last_response.body).to eq('rain!')
      end

      it 'defaults to a 500 status' do
        get '/'
        expect(last_response.status).to eq(500)
      end
    end

    context 'Non-StandardError exception' do
      let(:running_app) { other_exception_app }
      let(:options) { { rescue_all: true } }

      it 'does not trap errors other than StandardError' do
        expect { get '/' }.to raise_error(NotImplementedError, 'snow!')
      end
    end
  end

  context 'Non-StandardError exception with a provided rescue handler' do
    context 'default error response' do
      let(:running_app) { other_exception_app }
      let(:options) { { rescue_handlers: { NotImplementedError => nil } } }

      it 'rescues the exception using the default handler' do
        get '/'
        expect(last_response.body).to eq('snow!')
      end
    end

    context 'custom error response' do
      let(:running_app) { other_exception_app }
      let(:options) { { rescue_handlers: { NotImplementedError => -> { Rack::Response.new('rescued', 200, {}) } } } }

      it 'rescues the exception using the provided handler' do
        get '/'
        expect(last_response.body).to eq('rescued')
      end
    end
  end

  context do
    let(:running_app) { exception_app }
    let(:options) { { rescue_all: true, default_status: 500 } }

    it 'is possible to specify a different default status code' do
      get '/'
      expect(last_response.status).to eq(500)
    end
  end

  context do
    let(:running_app) { exception_app }
    let(:options) { { rescue_all: true, format: :json } }

    it 'is possible to return errors in json format' do
      get '/'
      expect(last_response.body).to eq('{"error":"rain!"}')
    end
  end

  context do
    let(:running_app) { error_hash_app }
    let(:options) { { rescue_all: true, format: :json } }

    it 'is possible to return hash errors in json format' do
      get '/'
      expect(['{"error":"rain!","detail":"missing widget"}',
              '{"detail":"missing widget","error":"rain!"}']).to include(last_response.body)
    end
  end

  context do
    let(:running_app) { exception_app }
    let(:options) { { rescue_all: true, format: :jsonapi } }

    it 'is possible to return errors in jsonapi format' do
      get '/'
      expect(last_response.body).to eq('{&quot;error&quot;:&quot;rain!&quot;}')
    end
  end

  context do
    let(:running_app) { error_hash_app }
    let(:options) { { rescue_all: true, format: :jsonapi } }

    it 'is possible to return hash errors in jsonapi format' do
      get '/'
      expect(['{&quot;error&quot;:&quot;rain!&quot;,&quot;detail&quot;:&quot;missing widget&quot;}',
              '{&quot;detail&quot;:&quot;missing widget&quot;,&quot;error&quot;:&quot;rain!&quot;}']).to include(last_response.body)
    end
  end

  context do
    let(:running_app) { exception_app }
    let(:options) { { rescue_all: true, format: :xml } }

    it 'is possible to return errors in xml format' do
      get '/'
      expect(last_response.body).to eq("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<error>\n  <message>rain!</message>\n</error>\n")
    end
  end

  context do
    let(:running_app) { error_hash_app }
    let(:options) { { rescue_all: true, format: :xml } }

    it 'is possible to return hash errors in xml format' do
      get '/'
      expect(["<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<error>\n  <detail>missing widget</detail>\n  <error>rain!</error>\n</error>\n",
              "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<error>\n  <error>rain!</error>\n  <detail>missing widget</detail>\n</error>\n"]).to include(last_response.body)
    end
  end

  context do
    let(:running_app) { exception_app }
    let(:options) do
      {
        rescue_all: true,
        format: :custom,
        error_formatters: {
          custom: lambda do |message, _backtrace, _options, _env, _original_exception|
            { custom_formatter: message }.inspect
          end
        }
      }
    end

    it 'is possible to specify a custom formatter' do
      get '/'
      expect(last_response.body).to eq('{:custom_formatter=&gt;&quot;rain!&quot;}')
    end
  end

  context do
    let(:running_app) { access_denied_app }
    let(:options) { {} }

    it 'does not trap regular error! codes' do
      get '/'
      expect(last_response.status).to eq(401)
    end
  end

  context do
    let(:running_app) { custom_error_app }
    let(:options) { { rescue_all: false } }

    it 'responds to custom Grape exceptions appropriately' do
      get '/'
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('failed validation')
    end
  end

  context 'with rescue_options :backtrace and :exception set to true' do
    let(:running_app) { exception_app }
    let(:options) do
      {
        rescue_all: true,
        format: :json,
        rescue_options: { backtrace: true, original_exception: true }
      }
    end

    it 'is possible to return the backtrace and the original exception in json format' do
      get '/'
      expect(last_response.body).to include('error', 'rain!', 'backtrace', 'original_exception', 'RuntimeError')
    end
  end

  context do
    let(:running_app) { exception_app }
    let(:options) do
      {
        rescue_all: true,
        format: :xml,
        rescue_options: { backtrace: true, original_exception: true }
      }
    end

    it 'is possible to return the backtrace and the original exception in xml format' do
      get '/'
      expect(last_response.body).to include('error', 'rain!', 'backtrace', 'original-exception', 'RuntimeError')
    end
  end

  context do
    let(:running_app) { exception_app }
    let(:options) do
      {
        rescue_all: true,
        format: :txt,
        rescue_options: { backtrace: true, original_exception: true }
      }
    end

    it 'is possible to return the backtrace and the original exception in txt format' do
      get '/'
      expect(last_response.body).to include('error', 'rain!', 'backtrace', 'original exception', 'RuntimeError')
    end
  end
end
