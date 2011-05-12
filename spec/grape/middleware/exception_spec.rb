require 'spec_helper'

describe Grape::Middleware::Error do
  class ExceptionApp
    class << self
      def call(env)
        raise "rain!"
      end
    end
  end

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
  
  def app
    @app
  end
  
  it 'should set the message appropriately' do
    @app ||= Rack::Builder.app do
      use Grape::Middleware::Error
      run ExceptionApp
    end
    get '/'
    last_response.body.should == "rain!"
  end

  it 'should default to a 403 status' do
    @app ||= Rack::Builder.app do
      use Grape::Middleware::Error
      run ExceptionApp
    end
    get '/'
    last_response.status.should == 403
  end

  it 'should be possible to specify a different default status code' do
    @app ||= Rack::Builder.app do
      use Grape::Middleware::Error, :default_status => 500
      run ExceptionApp
    end
    get '/'
    last_response.status.should == 500
  end
     
  it 'should be possible to disable exception trapping' do
    @app ||= Rack::Builder.app do
      use Grape::Middleware::Error, :rescue  => false
      run ExceptionApp
    end
    lambda { get '/' }.should raise_error
  end

  it 'should be possible to return errors in json format' do
    @app ||= Rack::Builder.app do
      use Grape::Middleware::Error, :format => :json
      run ExceptionApp
    end
    get '/'
    last_response.body.should == '{"error":"rain!"}'
  end

  it 'should be possible to specify a custom formatter' do
    @app ||= Rack::Builder.app do
      use Grape::Middleware::Error, 
        :format => :custom, 
        :formatters => { 
          :custom => lambda { |message, backtrace| { :custom_formatter => message } }  
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
  
end
