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

  # Regression: a cascading route used to hand straight over to the greedy
  # neighbour — the *last* route registered for the path — so any route
  # between the first match and that last one was unreachable.
  describe 'cascading routes' do
    subject(:router) { described_class.new }

    let(:pattern) do
      Grape::Router::Pattern.new(origin: '/hello', suffix: '', anchor: true, params: {}, version: nil, requirements: {})
    end
    let(:cascading) { ->(_env) { [404, { 'X-Cascade' => 'pass' }, []] } }
    let(:serving) { ->(_env) { [200, {}, ['served']] } }
    let(:any_handler) { ->(_env) { [200, {}, ['any']] } }

    def append_route(endpoint, method = :get)
      router.append(Grape::Router::Route.new(endpoint, method, pattern, {}, forward_match: false))
    end

    def response_body
      _, _, body = router.call(Rack::MockRequest.env_for('/hello'))
      body.each_with_object(+'') { |chunk, buffer| buffer << chunk }
    end

    it 'hands over to a sibling route registered after the cascading one' do
      append_route(cascading)
      append_route(cascading)
      append_route(serving)
      router.compile!

      expect(response_body).to eq('served')
    end

    it 'prefers a sibling of the same method over an ANY route' do
      append_route(cascading)
      append_route(serving)
      append_route(any_handler, '*')
      router.compile!

      expect(response_body).to eq('served')
    end

    it 'falls through to an ANY route once every sibling has cascaded' do
      append_route(cascading)
      append_route(cascading)
      append_route(any_handler, '*')
      router.compile!

      expect(response_body).to eq('any')
    end

    it 'returns the last cascading response when nothing else answers' do
      append_route(cascading)
      append_route(cascading)
      router.compile!

      status, headers, = router.call(Rack::MockRequest.env_for('/hello'))
      expect(status).to eq(404)
      expect(headers['X-Cascade']).to eq('pass')
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
