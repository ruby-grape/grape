require 'spec_helper'

describe Grape::Middleware::Base do
  subject { Grape::Middleware::Base.new(blank_app) }
  let(:blank_app) { lambda { |_| [200, {}, 'Hi there.'] } }

  before do
    # Keep it one object for testing.
    subject.stub(:dup).and_return(subject)
  end

  it 'has the app as an accessor' do
    subject.app.should == blank_app
  end

  it 'is able to access the request' do
    subject.call({})
    subject.request.should be_kind_of(Rack::Request)
  end

  it 'calls through to the app' do
    subject.call({}).should == [200, {}, 'Hi there.']
  end

  context 'callbacks' do
    it 'calls #before' do
      subject.should_receive(:before)
    end

    it 'calls #after' do
      subject.should_receive(:after)
    end

    after { subject.call!({}) }
  end

  it 'is able to access the response' do
    subject.call({})
    subject.response.should be_kind_of(Rack::Response)
  end

  context 'options' do
    it 'persists options passed at initialization' do
      Grape::Middleware::Base.new(blank_app, abc: true).options[:abc].should be_true
    end

    context 'defaults' do
      class ExampleWare < Grape::Middleware::Base
        def default_options
          { monkey: true }
        end
      end

      it 'persists the default options' do
        ExampleWare.new(blank_app).options[:monkey].should be_true
      end

      it 'overrides default options when provided' do
        ExampleWare.new(blank_app, monkey: false).options[:monkey].should be_false
      end
    end
  end
end
