# frozen_string_literal: true

describe Grape::Endpoint::Options do
  describe '#path' do
    subject { described_class.new(path: paths, http_methods: :get, api: nil).path }

    context 'when a String' do
      let(:paths) { '/users' }

      it { is_expected.to eq(['/users']) }
    end

    context 'when a non-empty Array' do
      let(:paths) { ['/users', '/people'] }

      it { is_expected.to eq(['/users', '/people']) }

      it 'does not modify the Array it was given' do
        subject
        expect(paths).to eq(['/users', '/people'])
      end
    end

    context 'when an empty Array' do
      let(:paths) { [] }

      it { is_expected.to eq(['/']) }

      it 'does not append the default to the Array it was given' do
        subject
        expect(paths).to be_empty
      end
    end

    context 'when a frozen empty Array' do
      let(:paths) { [].freeze }

      it { is_expected.to eq(['/']) }
    end
  end

  describe '#http_methods' do
    subject { described_class.new(path: '/', http_methods: methods, api: nil).http_methods }

    context 'when a Symbol' do
      let(:methods) { :get }

      it { is_expected.to eq([:get]) }
    end

    context 'when an Array' do
      let(:methods) { %i[get post] }

      it { is_expected.to eq(%i[get post]) }
    end
  end

  # The reachable path through the public DSL: a route nested in a namespace,
  # resource, group or route_param block reaches Grape::Endpoint directly. A
  # top-level route does not, because Grape::API replays recorded setup steps
  # through `evaluate_arguments`, which rebuilds Array arguments on the way in.
  context 'when a route is defined inside a namespace' do
    let(:paths) { [] }
    let(:app) do
      route_paths = paths
      Class.new(Grape::API) do
        format :txt
        namespace :v1 do
          get(route_paths) { 'ok' }
        end
      end
    end

    it 'routes the default path' do
      get '/v1'
      expect(last_response.body).to eq('ok')
    end

    it "leaves the caller's Array untouched" do
      app.routes
      expect(paths).to be_empty
    end

    context 'when the Array is frozen' do
      let(:paths) { [].freeze }

      it 'defines the API without raising' do
        expect { app.routes }.not_to raise_error
      end
    end
  end
end
