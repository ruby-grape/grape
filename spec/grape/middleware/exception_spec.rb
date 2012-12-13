require 'spec_helper'
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
      def error!(message, status=403)
        throw :error, :message => { :error => message, :detail => "missing widget" }, :status => status
      end
      def call(env)
        error!("rain!", 401)
      end
    end
  end

  # raises an error!
  class AccessDeniedApp
    class << self
      def error!(message, status=403)
        throw :error, :message => message, :status => status
      end
      def call(env)
        error!("Access Denied", 401)
      end
    end
  end

  # raises a custom error
  class CustomError < Grape::Exceptions::Base; end
  class CustomErrorApp
    class << self
      def call(env)
        raise CustomError, :status => 400, :message => 'failed validation'
      end
    end
  end

  def app
    @app
  end

  it 'should not trap errors by default' do
    @app ||= Rack::Builder.app do
      use Grape::Middleware::Error
      run ExceptionApp
    end
    lambda { get '/' }.should raise_error
  end

  context 'with rescue_all set to true' do
    it 'should set the message appropriately' do
      @app ||= Rack::Builder.app do
        use Grape::Middleware::Error, :rescue_all => true
        run ExceptionApp
      end
      get '/'
      last_response.body.should == "rain!"
    end

    it 'should default to a 403 status' do
      @app ||= Rack::Builder.app do
        use Grape::Middleware::Error, :rescue_all => true
        run ExceptionApp
      end
      get '/'
      last_response.status.should == 403
    end

    it 'should be possible to specify a different default status code' do
      @app ||= Rack::Builder.app do
        use Grape::Middleware::Error, :rescue_all => true, :default_status => 500
        run ExceptionApp
      end
      get '/'
      last_response.status.should == 500
    end

    it 'should be possible to return errors in json format' do
      @app ||= Rack::Builder.app do
        use Grape::Middleware::Error, :rescue_all => true, :format => :json
        run ExceptionApp
      end
      get '/'
      last_response.body.should == '{"error":"rain!"}'
    end

    it 'should be possible to return hash errors in json format' do
      @app ||= Rack::Builder.app do
        use Grape::Middleware::Error, :rescue_all => true, :format => :json
        run ErrorHashApp
      end
      get '/'
      ['{"error":"rain!","detail":"missing widget"}',
       '{"detail":"missing widget","error":"rain!"}'].should be_include(last_response.body)
    end

    it 'should be possible to return errors in xml format' do
      @app ||= Rack::Builder.app do
        use Grape::Middleware::Error, :rescue_all => true, :format => :xml
        run ExceptionApp
      end
      get '/'
      last_response.body.should == {:message=>"rain!"}.to_s
    end

    it 'should be possible to return hash errors in xml format' do
      @app ||= Rack::Builder.app do
        use Grape::Middleware::Error, :rescue_all => true, :format => :xml
        run ErrorHashApp
      end
      get '/'
      [{:error=>"rain!", :detail=>"missing widget"}.to_s,
       {:detail=>"missing widget", :error=>"rain!"}.to_s].should be_include(last_response.body)
    end

    it 'should be possible to specify a custom formatter' do
      @app ||= Rack::Builder.app do
        use Grape::Middleware::Error,
          :rescue_all => true,
          :format => :custom,
          :error_formatters => {
            :custom => lambda { |message, backtrace, options|
              { :custom_formatter => message }.inspect
            }
          }
        run ExceptionApp
      end
      get '/'
      last_response.body.should == '{:custom_formatter=>"rain!"}'
    end

    it 'should not trap regular error! codes' do
      @app ||= Rack::Builder.app do
        use Grape::Middleware::Error
        run AccessDeniedApp
      end
      get '/'
      last_response.status.should == 401
    end

    it 'should respond to custom Grape exceptions appropriately' do
      @app ||= Rack::Builder.app do
        use Grape::Middleware::Error, :rescue_all => false
        run CustomErrorApp
      end

      get '/'
      last_response.status.should == 400
      last_response.body.should == 'failed validation'
    end

  end
end
