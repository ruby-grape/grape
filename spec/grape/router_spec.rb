# frozen_string_literal: true

describe Grape::Router do
  describe '.normalize_path' do
    it 'is deprecated and delegates to Grape::Util::PathNormalizer' do
      expect { described_class.normalize_path('/foo/') }.to raise_error(
        ActiveSupport::DeprecationException, /Grape::Util::PathNormalizer/
      )
    end
  end

  describe 'request-time map isolation' do
    subject(:router) { described_class.new }

    let(:endpoint) { instance_double(Grape::Endpoint) }
    let(:pattern) do
      Grape::Router::Pattern.new(origin: '/hello', suffix: '', anchor: true, params: {}, version: nil, requirements: {})
    end
    let(:route) { Grape::Router::Route.new(endpoint, :get, pattern, {}, forward_match: false) }

    before do
      router.append(route)
      router.compile!
    end

    it 'freezes the internal maps after compilation' do
      expect(router.instance_variable_get(:@map)).to be_frozen
      expect(router.instance_variable_get(:@optimized_map)).to be_frozen
    end

    # Regression: the maps used to be auto-vivifying hashes, so a request whose
    # HTTP method had no routes inserted a key at request time — a data race
    # under concurrency and unbounded growth from arbitrary methods.
    it 'does not mutate the maps when routing a method that has no routes' do
      map = router.instance_variable_get(:@map)
      optimized_map = router.instance_variable_get(:@optimized_map)
      keys_before = [map.keys.sort, optimized_map.keys.sort]

      %w[POST PUT PROPFIND CUSTOM].each do |http_method|
        router.call(Rack::MockRequest.env_for('/hello', method: http_method))
      end

      expect([map.keys.sort, optimized_map.keys.sort]).to eq(keys_before)
    end

    it 'routes a method with no routes to the default 404 response without error' do
      status, = router.call(Rack::MockRequest.env_for('/hello', method: 'POST'))
      expect(status).to eq(404)
    end
  end

  # Regression: routing args were seeded once (`||=`) and merged in place, so
  # when a route cascaded (X-Cascade pass) the next candidate still saw the
  # previous attempt's :route_info and path captures.
  describe 'routing args across cascading routes' do
    let(:app) do
      v2 = Class.new(Grape::API) do
        version 'v2', using: :header, vendor: 'grape', cascade: true
        get ':id' do
          { from: 'v2' }
        end
      end
      v1 = Class.new(Grape::API) do
        format :json
        version 'v1', using: :header, vendor: 'grape'
        get ':name' do
          { origin: route.origin, params: params.to_h }
        end
      end
      Class.new(Grape::API) do
        format :json
        mount v2
        mount v1
      end
    end

    it 'does not leak route_info or path captures from a cascaded attempt' do
      get '/123', {}, 'HTTP_ACCEPT' => 'application/vnd.grape-v1+json'

      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body['origin']).to eq('/:name')
      expect(body['params']).to eq('name' => '123')
    end
  end
end
