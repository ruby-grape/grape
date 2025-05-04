# frozen_string_literal: true

describe Grape::Middleware::Base do
  subject { described_class.new(blank_app) }

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
    after { subject.call!({}) }

    it 'calls #before' do
      expect(subject).to receive(:before)
    end

    it 'calls #after' do
      expect(subject).to receive(:after)
    end
  end

  context 'callbacks on error' do
    let(:blank_app) { ->(_) { raise StandardError } }

    it 'calls #after' do
      expect(subject).to receive(:after)
      expect { subject.call({}) }.to raise_error(StandardError)
    end
  end

  context 'after callback' do
    before do
      allow(subject).to receive(:after).and_return([200, {}, 'Hello from after callback'])
    end

    it 'overwrites application response' do
      expect(subject.call!({}).last).to eq('Hello from after callback')
    end
  end

  context 'after callback with errors' do
    it 'does not overwrite the application response' do
      expect(subject.call({})).to eq([200, {}, 'Hi there.'])
    end

    context 'with patched warnings' do
      before do
        @warnings = warnings = []
        allow(subject).to receive(:warn) { |m| warnings << m }
        allow(subject).to receive(:after).and_raise(StandardError)
      end

      it 'does show a warning' do
        expect { subject.call({}) }.to raise_error(StandardError)
        expect(@warnings).not_to be_empty
      end
    end
  end

  it 'is able to access the response' do
    subject.call({})
    expect(subject.response).to be_a(Rack::Response)
  end

  describe '#response' do
    subject do
      described_class.new(response)
    end

    before { subject.call({}) }

    context 'when Array' do
      let(:rack_response) { Rack::Response.new('test', 204, abc: 1) }
      let(:response) { ->(_) { [204, { abc: 1 }, 'test'] } }

      it 'status' do
        expect(subject.response.status).to eq(204)
      end

      it 'body' do
        expect(subject.response.body).to eq(['test'])
      end

      it 'header' do
        expect(subject.response.headers).to have_key(:abc)
      end

      it 'returns the memoized Rack::Response instance' do
        allow(Rack::Response).to receive(:new).and_return(rack_response)
        expect(subject.response).to eq(rack_response)
      end
    end

    context 'when Rack::Response' do
      let(:rack_response) { Rack::Response.new('test', 204, abc: 1) }
      let(:response) { ->(_) { rack_response } }

      it 'status' do
        expect(subject.response.status).to eq(204)
      end

      it 'body' do
        expect(subject.response.body).to eq(['test'])
      end

      it 'header' do
        expect(subject.response.headers).to have_key(:abc)
      end

      it 'returns the memoized Rack::Response instance' do
        expect(subject.response).to eq(rack_response)
      end
    end
  end

  describe '#context' do
    subject { described_class.new(blank_app) }

    it 'allows access to response context' do
      subject.call(Grape::Env::API_ENDPOINT => { header: 'some header' })
      expect(subject.context).to eq(header: 'some header')
    end
  end

  context 'options' do
    it 'persists options passed at initialization' do
      expect(described_class.new(blank_app, abc: true).options[:abc]).to be true
    end

    context 'defaults' do
      let(:example_ware) do
        Class.new(Grape::Middleware::Base) do
          const_set(:DEFAULT_OPTIONS, { monkey: true }.freeze)
        end
      end

      it 'persists the default options' do
        expect(example_ware.new(blank_app).options[:monkey]).to be true
      end

      it 'overrides default options when provided' do
        expect(example_ware.new(blank_app, monkey: false).options[:monkey]).to be false
      end
    end
  end

  context 'header' do
    let(:example_ware) do
      Class.new(Grape::Middleware::Base) do
        def before
          header 'X-Test-Before', 'Hi'
        end

        def after
          header 'X-Test-After', 'Bye'
          nil
        end
      end
    end

    let(:app) do
      context = self

      Rack::Builder.app do
        use context.example_ware
        run ->(_) { [200, {}, ['Yeah']] }
      end
    end

    it 'is able to set a header' do
      get '/'
      expect(last_response.headers['X-Test-Before']).to eq('Hi')
      expect(last_response.headers['X-Test-After']).to eq('Bye')
    end
  end

  context 'header overwrite' do
    let(:example_ware) do
      Class.new(Grape::Middleware::Base) do
        def before
          header 'X-Test-Overwriting', 'Hi'
        end

        def after
          header 'X-Test-Overwriting', 'Bye'
          nil
        end
      end
    end
    let(:api) do
      Class.new(Grape::API) do
        get('/') do
          header 'X-Test-Overwriting', 'Yeah'
          'Hello'
        end
      end
    end

    let(:app) do
      context = self

      Rack::Builder.app do
        use context.example_ware
        run context.api.new
      end
    end

    it 'overwrites header by after headers' do
      get '/'
      expect(last_response.headers['X-Test-Overwriting']).to eq('Bye')
    end
  end

  describe 'query_params' do
    let(:dummy_middleware) do
      Class.new(Grape::Middleware::Base) do
        def before
          query_params
        end
      end
    end

    let(:app) do
      context = self
      Rack::Builder.app do
        use context.dummy_middleware
        run ->(_) { [200, {}, ['Yeah']] }
      end
    end

    context 'when query params are conflicting' do
      it 'raises an ConflictingTypes error' do
        expect { get '/?x[y]=1&x[y]z=2' }.to raise_error(Grape::Exceptions::ConflictingTypes)
      end
    end

    context 'when query params is over the specified limit' do
      let(:query_params) { "foo#{'[a]' * Rack::Utils.param_depth_limit}=bar" }

      it 'raises an ConflictingTypes error' do
        expect { get "/?foo#{'[a]' * Rack::Utils.param_depth_limit}=bar" }.to raise_error(Grape::Exceptions::TooDeepParameters)
      end
    end
  end
end
