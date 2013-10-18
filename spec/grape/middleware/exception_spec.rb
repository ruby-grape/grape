require 'spec_helper'
require 'active_support/core_ext/hash'

describe Grape::Middleware::Error do

  # raises a text exception
  class ExceptionApp
    class << self
      def call(env)
        raise "rain!"
      end
    end
  end

  # raises a hash error
  class ErrorHashApp
    class << self
      def error!(message, status = 403)
        throw :error, message: { error: message, detail: "missing widget" }, status: status
      end

      def call(env)
        error!("rain!", 401)
      end
    end
  end

  # raises an error!
  class AccessDeniedApp
    class << self
      def error!(message, status = 403)
        throw :error, message: message, status: status
      end

      def call(env)
        error!("Access Denied", 401)
      end
    end
  end

  # raises a custom error
  class CustomError < Grape::Exceptions::Base
  end

  class CustomErrorApp
    class << self
      def call(env)
        raise CustomError, status: 400, message: 'failed validation'
      end
    end
  end

  attr_reader :app

  it 'does not trap errors by default' do
    @app ||= Rack::Builder.app do
      use Grape::Middleware::Error
      run ExceptionApp
    end
    lambda { get '/' }.should raise_error
  end

  context 'with rescue_all set to true' do
    it 'sets the message appropriately' do
      @app ||= Rack::Builder.app do
        use Grape::Middleware::Error, rescue_all: true
        run ExceptionApp
      end
      get '/'
      last_response.body.should == "rain!"
    end

    it 'defaults to a 403 status' do
      @app ||= Rack::Builder.app do
        use Grape::Middleware::Error, rescue_all: true
        run ExceptionApp
      end
      get '/'
      last_response.status.should == 403
    end

    it 'is possible to specify a different default status code' do
      @app ||= Rack::Builder.app do
        use Grape::Middleware::Error, rescue_all: true, default_status: 500
        run ExceptionApp
      end
      get '/'
      last_response.status.should == 500
    end

    it 'is possible to return errors in json format' do
      @app ||= Rack::Builder.app do
        use Grape::Middleware::Error, rescue_all: true, format: :json
        run ExceptionApp
      end
      get '/'
      last_response.body.should == '{"error":"rain!"}'
    end

    it 'is possible to return hash errors in json format' do
      @app ||= Rack::Builder.app do
        use Grape::Middleware::Error, rescue_all: true, format: :json
        run ErrorHashApp
      end
      get '/'
      ['{"error":"rain!","detail":"missing widget"}',
       '{"detail":"missing widget","error":"rain!"}'].should include(last_response.body)
    end

    it 'is possible to return errors in jsonapi format' do
      @app ||= Rack::Builder.app do
        use Grape::Middleware::Error, rescue_all: true, format: :jsonapi
        run ExceptionApp
      end
      get '/'
      last_response.body.should == '{"error":"rain!"}'
    end

    it 'is possible to return hash errors in jsonapi format' do
      @app ||= Rack::Builder.app do
        use Grape::Middleware::Error, rescue_all: true, format: :jsonapi
        run ErrorHashApp
      end
      get '/'
      ['{"error":"rain!","detail":"missing widget"}',
       '{"detail":"missing widget","error":"rain!"}'].should include(last_response.body)
    end

    it 'is possible to return errors in xml format' do
      @app ||= Rack::Builder.app do
        use Grape::Middleware::Error, rescue_all: true, format: :xml
        run ExceptionApp
      end
      get '/'
      last_response.body.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<error>\n  <message>rain!</message>\n</error>\n"
    end

    it 'is possible to return hash errors in xml format' do
      @app ||= Rack::Builder.app do
        use Grape::Middleware::Error, rescue_all: true, format: :xml
        run ErrorHashApp
      end
      get '/'
      ["<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<error>\n  <detail>missing widget</detail>\n  <error>rain!</error>\n</error>\n",
       "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<error>\n  <error>rain!</error>\n  <detail>missing widget</detail>\n</error>\n"].should include(last_response.body)
    end

    it 'is possible to specify a custom formatter' do
      @app ||= Rack::Builder.app do
        use Grape::Middleware::Error, rescue_all: true,
                                      format: :custom,
                                      error_formatters: {
                                        custom: lambda { |message, backtrace, options, env|
                                          { custom_formatter: message }.inspect
                                        }
                                      }
        run ExceptionApp
      end
      get '/'
      last_response.body.should == '{:custom_formatter=>"rain!"}'
    end

    it 'does not trap regular error! codes' do
      @app ||= Rack::Builder.app do
        use Grape::Middleware::Error
        run AccessDeniedApp
      end
      get '/'
      last_response.status.should == 401
    end

    it 'responds to custom Grape exceptions appropriately' do
      @app ||= Rack::Builder.app do
        use Grape::Middleware::Error, rescue_all: false
        run CustomErrorApp
      end

      get '/'
      last_response.status.should == 400
      last_response.body.should == 'failed validation'
    end

  end
end
