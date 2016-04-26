require 'spec_helper'

describe Grape::Middleware::Error do
  # raises a text exception
  module ExceptionSpec
    class ExceptionApp
      class << self
        def call(_env)
          raise 'rain!'
        end
      end
    end

    # raises a hash error
    class ErrorHashApp
      class << self
        def error!(message, status)
          throw :error, message: { error: message, detail: 'missing widget' }, status: status
        end

        def call(_env)
          error!('rain!', 401)
        end
      end
    end

    # raises an error!
    class AccessDeniedApp
      class << self
        def error!(message, status)
          throw :error, message: message, status: status
        end

        def call(_env)
          error!('Access Denied', 401)
        end
      end
    end

    # raises a custom error
    class CustomError < Grape::Exceptions::Base
    end

    class CustomErrorApp
      class << self
        def call(_env)
          raise CustomError, status: 400, message: 'failed validation'
        end
      end
    end
  end

  attr_reader :app

  it 'does not trap errors by default' do
    @app ||= Rack::Builder.app do
      use Spec::Support::EndpointFaker
      use Grape::Middleware::Error
      run ExceptionSpec::ExceptionApp
    end
    expect { get '/' }.to raise_error(RuntimeError, 'rain!')
  end

  context 'with rescue_all set to true' do
    it 'sets the message appropriately' do
      @app ||= Rack::Builder.app do
        use Spec::Support::EndpointFaker
        use Grape::Middleware::Error, rescue_all: true
        run ExceptionSpec::ExceptionApp
      end
      get '/'
      expect(last_response.body).to eq('rain!')
    end

    it 'defaults to a 500 status' do
      @app ||= Rack::Builder.app do
        use Spec::Support::EndpointFaker
        use Grape::Middleware::Error, rescue_all: true
        run ExceptionSpec::ExceptionApp
      end
      get '/'
      expect(last_response.status).to eq(500)
    end

    it 'is possible to specify a different default status code' do
      @app ||= Rack::Builder.app do
        use Spec::Support::EndpointFaker
        use Grape::Middleware::Error, rescue_all: true, default_status: 500
        run ExceptionSpec::ExceptionApp
      end
      get '/'
      expect(last_response.status).to eq(500)
    end

    it 'is possible to return errors in json format' do
      @app ||= Rack::Builder.app do
        use Spec::Support::EndpointFaker
        use Grape::Middleware::Error, rescue_all: true, format: :json
        run ExceptionSpec::ExceptionApp
      end
      get '/'
      expect(last_response.body).to eq('{"error":"rain!"}')
    end

    it 'is possible to return hash errors in json format' do
      @app ||= Rack::Builder.app do
        use Spec::Support::EndpointFaker
        use Grape::Middleware::Error, rescue_all: true, format: :json
        run ExceptionSpec::ErrorHashApp
      end
      get '/'
      expect(['{"error":"rain!","detail":"missing widget"}',
              '{"detail":"missing widget","error":"rain!"}']).to include(last_response.body)
    end

    it 'is possible to return errors in jsonapi format' do
      @app ||= Rack::Builder.app do
        use Spec::Support::EndpointFaker
        use Grape::Middleware::Error, rescue_all: true, format: :jsonapi
        run ExceptionSpec::ExceptionApp
      end
      get '/'
      expect(last_response.body).to eq('{"error":"rain!"}')
    end

    it 'is possible to return hash errors in jsonapi format' do
      @app ||= Rack::Builder.app do
        use Spec::Support::EndpointFaker
        use Grape::Middleware::Error, rescue_all: true, format: :jsonapi
        run ExceptionSpec::ErrorHashApp
      end
      get '/'
      expect(['{"error":"rain!","detail":"missing widget"}',
              '{"detail":"missing widget","error":"rain!"}']).to include(last_response.body)
    end

    it 'is possible to return errors in xml format' do
      @app ||= Rack::Builder.app do
        use Spec::Support::EndpointFaker
        use Grape::Middleware::Error, rescue_all: true, format: :xml
        run ExceptionSpec::ExceptionApp
      end
      get '/'
      expect(last_response.body).to eq("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<error>\n  <message>rain!</message>\n</error>\n")
    end

    it 'is possible to return hash errors in xml format' do
      @app ||= Rack::Builder.app do
        use Spec::Support::EndpointFaker
        use Grape::Middleware::Error, rescue_all: true, format: :xml
        run ExceptionSpec::ErrorHashApp
      end
      get '/'
      expect(["<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<error>\n  <detail>missing widget</detail>\n  <error>rain!</error>\n</error>\n",
              "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<error>\n  <error>rain!</error>\n  <detail>missing widget</detail>\n</error>\n"]).to include(last_response.body)
    end

    it 'is possible to specify a custom formatter' do
      @app ||= Rack::Builder.app do
        use Spec::Support::EndpointFaker
        use Grape::Middleware::Error, rescue_all: true,
                                      format: :custom,
                                      error_formatters: {
                                        custom: lambda do |message, _backtrace, _options, _env|
                                          { custom_formatter: message }.inspect
                                        end
                                      }
        run ExceptionSpec::ExceptionApp
      end
      get '/'
      expect(last_response.body).to eq('{:custom_formatter=>"rain!"}')
    end

    it 'does not trap regular error! codes' do
      @app ||= Rack::Builder.app do
        use Spec::Support::EndpointFaker
        use Grape::Middleware::Error
        run ExceptionSpec::AccessDeniedApp
      end
      get '/'
      expect(last_response.status).to eq(401)
    end

    it 'responds to custom Grape exceptions appropriately' do
      @app ||= Rack::Builder.app do
        use Spec::Support::EndpointFaker
        use Grape::Middleware::Error, rescue_all: false
        run ExceptionSpec::CustomErrorApp
      end

      get '/'
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('failed validation')
    end
  end
end
