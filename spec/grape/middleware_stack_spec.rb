require 'spec_helper'

describe Grape::MiddlewareStack do
  subject { Grape::MiddlewareStack.new }
  
  it 'should be able to add middlewares' do
    subject.use Grape::Middleware::Error
    subject.stack.first.should == [Grape::Middleware::Error]
  end
  
  context 'class uniqueness' do
    it 'should not increase the stack size when doubling up on a use' do
      2.times{ subject.use Grape::Middleware::Error }
      subject.stack.size.should == 1
    end
    
    it 'should increase the stack size when a novel class is added' do
      subject.use Grape::Middleware::Error
      subject.use Grape::Middleware::Prefixer
      subject.use Grape::Middleware::Error
      subject.stack.should == [[Grape::Middleware::Error], [Grape::Middleware::Prefixer]]
    end
  end
  
  describe '#run' do
    class ExampleMiddleware
      def initialize(app, say = 'what')
        @app = app
        @say = say
      end

      def call(env)
        (env['say'] ||= []) << @say
        @app.call(env)
      end
    end
    
    before do
      subject.use ExampleMiddleware
      subject.use ExampleMiddleware, 'yo'
    end
    
    it 'should call the middlewares in the stack' do
      subject.to_app(lambda{|env| env['say'].should == ['yo']}).call({})
    end
  end
end