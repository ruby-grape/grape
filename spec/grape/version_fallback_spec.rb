require 'spec_helper'
require 'shared/versioning_examples'

describe Grape::API do
  subject { Class.new(Grape::API) }

  def app
    subject
  end

  before do
    api1 = Class.new(Grape::API)
    api1.version %w(v3 v2 v1), version_options
    api1.get('all') { 'v1' }
    api1.get('only_v1') { 'only_v1' }

    api2 = Class.new(Grape::API)
    api2.version %w(v3 v2), version_options
    api2.get('all') { 'v2' }
    api2.get('only_v2') { 'only_v2' }

    api3 = Class.new(Grape::API)
    api3.version 'v3', version_options
    api3.get('all') { 'v3' }

    app.mount api3
    app.mount api2
    app.mount api1
  end

  shared_examples 'version fallback' do
    it 'returns the correct version' do
      versioned_get '/all', 'v1', version_options
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('v1')

      versioned_get '/all', 'v2', version_options
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('v2')

      versioned_get '/all', 'v3', version_options
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('v3')

      versioned_get '/only_v1', 'v2', version_options
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('only_v1')

      versioned_get '/only_v1', 'v3', version_options
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('only_v1')

      versioned_get '/only_v2', 'v3', version_options
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('only_v2')
    end
  end

  context 'with catch-all' do
    before do
      app.route :any, '*path' do
        error!("Unrecognized request path: #{params[:path]} - #{env['PATH_INFO']}#{env['SCRIPT_NAME']}", 404)
      end
    end

    shared_examples 'catch-all' do
      it 'returns a 404' do
        get '/foobar'
        expect(last_response.status).to eq(404)
        expect(last_response.body).to eq('Unrecognized request path: foobar - /foobar')
      end
    end

    context 'using path' do
      let(:version_options) { { using: :path } }

      it_behaves_like 'version fallback'
      it_behaves_like 'catch-all'
    end

    context 'using param' do
      let(:version_options) { { using: :param } }

      it_behaves_like 'version fallback'
      it_behaves_like 'catch-all'
    end

    context 'using accept_version_header' do
      let(:version_options) { { using: :accept_version_header } }

      it_behaves_like 'version fallback'
      it_behaves_like 'catch-all'
    end

    context 'using header' do
      let(:version_options) { { using: :header, vendor: 'test' } }

      it_behaves_like 'version fallback'
      it_behaves_like 'catch-all'
    end
  end

  context 'without catch-all' do
    context 'using path' do
      let(:version_options) { { using: :path } }

      it_behaves_like 'version fallback'
    end

    context 'using param' do
      let(:version_options) { { using: :param } }

      it_behaves_like 'version fallback'
    end

    context 'using accept_version_header' do
      let(:version_options) { { using: :accept_version_header } }

      it_behaves_like 'version fallback'
    end

    context 'using header' do
      let(:version_options) { { using: :header, vendor: 'test' } }

      it_behaves_like 'version fallback'
    end
  end
end
