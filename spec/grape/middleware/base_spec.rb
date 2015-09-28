require 'spec_helper'

describe Grape::Middleware::Base do
  subject { Grape::Middleware::Base.new(blank_app) }
  let(:blank_app) { ->(_) { [200, {}, 'Hi there.'] } }

  before do
    # Keep it one object for testing.
    allow(subject).to receive(:dup).and_return(subject)
  end

  it 'has the app as an accessor' do
    expect(subject.app).to eq(blank_app)
  end

  it 'calls through to the app' do
    expect(subject.call({})).to eq([200, {}, 'Hi there.'])
  end

  context 'callbacks' do
    it 'calls #before' do
      expect(subject).to receive(:before)
    end

    it 'calls #after' do
      expect(subject).to receive(:after)
    end

    after { subject.call!({}) }
  end

  it 'is able to access the response' do
    subject.call({})
    expect(subject.response).to be_kind_of(Rack::Response)
  end

  describe '#response' do
    subject { Grape::Middleware::Base.new(response) }

    context Array do
      let(:response) { ->(_) { [204, { abc: 1 }, 'test'] } }

      it 'status' do
        subject.call({})
        expect(subject.response.status).to eq(204)
      end

      it 'body' do
        subject.call({})
        expect(subject.response.body).to eq(['test'])
      end

      it 'header' do
        subject.call({})
        expect(subject.response.header).to have_key(:abc)
      end
    end

    context Rack::Response do
      let(:response) { ->(_) { Rack::Response.new('test', 204, abc: 1) } }

      it 'status' do
        subject.call({})
        expect(subject.response.status).to eq(204)
      end

      it 'body' do
        subject.call({})
        expect(subject.response.body).to eq(['test'])
      end

      it 'header' do
        subject.call({})
        expect(subject.response.header).to have_key(:abc)
      end
    end
  end

  context 'options' do
    it 'persists options passed at initialization' do
      expect(Grape::Middleware::Base.new(blank_app, abc: true).options[:abc]).to be true
    end

    context 'defaults' do
      module BaseSpec
        class ExampleWare < Grape::Middleware::Base
          def default_options
            { monkey: true }
          end
        end
      end

      it 'persists the default options' do
        expect(BaseSpec::ExampleWare.new(blank_app).options[:monkey]).to be true
      end

      it 'overrides default options when provided' do
        expect(BaseSpec::ExampleWare.new(blank_app, monkey: false).options[:monkey]).to be false
      end
    end
  end
end
