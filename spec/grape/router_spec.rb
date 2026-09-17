# frozen_string_literal: true

describe Grape::Router do
  # Regression: the maps used to be auto-vivifying hashes, so a request whose
  # HTTP method had no routes inserted a key at request time — a data race
  # under concurrency and unbounded growth from arbitrary methods. A compiled
  # router freezes its maps, and Grape::API::Instance freezes the router
  # itself, so a write like that raises rather than passing silently: routing
  # such a request without error is what shows none happens.
  describe 'routing a method that has no routes' do
    subject(:router) { described_class.new }

    let(:endpoint) { instance_double(Grape::Endpoint) }
    let(:pattern) do
      Grape::Router::Pattern.new(origin: '/hello', suffix: '', anchor: true, params: {}, version: nil, requirements: {})
    end
    let(:route) { Grape::Router::Route.new(endpoint, :get, pattern, {}, forward_match: false) }

    before do
      router.append(route)
      router.compile!
      router.freeze
    end

    %w[POST PUT PROPFIND CUSTOM].each do |http_method|
      it "answers #{http_method} with the default 404" do
        status, = router.call(Rack::MockRequest.env_for('/hello', method: http_method))

        expect(status).to eq(404)
      end
    end
  end

  # Regression: the optimized map was compiled from Grape::HTTP_SUPPORTED_METHODS,
  # so a route registered for any other verb stayed in @map and out of the map
  # #match? reads. It was advertised in the resource's Allow header and then
  # 405'd on every request.
  describe 'routes registered with a non-standard HTTP method' do
    subject(:router) { described_class.new }

    let(:endpoint) { ->(_env) { [200, {}, ['purged']] } }
    let(:pattern) do
      Grape::Router::Pattern.new(origin: '/cache', suffix: '', anchor: true, params: {}, version: nil, requirements: {})
    end

    before do
      router.append(Grape::Router::Route.new(endpoint, :purge, pattern, {}, forward_match: false))
      router.compile!
    end

    it 'matches a request using that method' do
      status, _, body = router.call(Rack::MockRequest.env_for('/cache', method: 'PURGE'))

      expect(status).to eq(200)
      expect(body.to_a).to eq(['purged'])
    end

    it 'still 404s a method that has no routes' do
      status, = router.call(Rack::MockRequest.env_for('/cache', method: 'PROPFIND'))

      expect(status).to eq(404)
    end
  end

  describe 'routing static paths' do
    subject(:router) { described_class.new }

    def append_route(endpoint, origin:, version: nil)
      pattern = Grape::Router::Pattern.new(origin:, suffix: '', anchor: true, params: {}, version:, requirements: {})
      router.append(Grape::Router::Route.new(endpoint, :get, pattern, {}, forward_match: false))
    end

    it 'preserves an earlier parameterized route and fresh captured values' do
      captured_ids = []
      dynamic_endpoint = lambda do |env|
        id = env.fetch(Grape::Env::GRAPE_ROUTING_ARGS).fetch(:id)
        captured_ids << id.dup
        id << '!'
        [200, {}, [id]]
      end
      append_route(dynamic_endpoint, origin: '/:id')
      append_route(->(_env) { raise 'the parameterized route should match first' }, origin: '/status')
      router.compile!

      bodies = Array.new(2) do
        status, _, body = router.call(Rack::MockRequest.env_for('/status'))
        expect(status).to eq(200)

        body.to_a.join
      end

      expect(bodies).to eq(%w[status! status!])
      expect(captured_ids).to eq(%w[status status])
    end

    it 'routes every declared path version' do
      versions = []
      endpoint = lambda do |env|
        versions << env.fetch(Grape::Env::GRAPE_ROUTING_ARGS).fetch(:version)
        [200, {}, ['ok']]
      end
      append_route(endpoint, origin: '/:version/status', version: %w[v1 v2])
      router.compile!

      %w[v1 v2].each do |version|
        status, = router.call(Rack::MockRequest.env_for("/#{version}/status"))
        expect(status).to eq(200)
      end

      expect(versions).to eq(%w[v1 v2])
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

    it 'marks the request as cascaded when only an ANY route responds' do
      append_route(cascading, '*')
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

  # Regression: Rack hands PATH_INFO over binary, and a binary string holding
  # non-ASCII bytes raises when matched against a UTF-8 regexp. A route whose
  # path holds a non-ASCII literal compiles to one, so on such an API every
  # path carrying raw non-ASCII bytes raised instead of routing.
  describe 'routing a binary path holding non-ASCII bytes' do
    let(:app) do
      Class.new(Grape::API) do
        get('/café') { 'static non-ascii literal' }
        get('/café/:id') { "non-ascii literal #{params[:id]}" }
        get('/plain/:id') { "plain #{params[:id] == 'é'}" }
      end
    end

    def request_path(path)
      env = Rack::MockRequest.env_for('/')
      env[Rack::PATH_INFO] = path.b
      status, _, body = app.call(env)
      buffer = +''
      body.each { |chunk| buffer << chunk }
      body.close if body.respond_to?(:close)
      [status, buffer]
    end

    it 'routes a UTF-8 path to the route with a non-ASCII literal' do
      expect(request_path('/café/42')).to eq([200, 'non-ascii literal 42'])
    end

    it 'routes a UTF-8 path to a route spelling out a non-ASCII literal in full' do
      expect(request_path('/café')).to eq([200, 'static non-ascii literal'])
    end

    it 'routes a UTF-8 path to an ASCII route of the same API' do
      expect(request_path('/plain/é')).to eq([200, 'plain true'])
    end

    it 'answers a path whose bytes are not UTF-8 as one no route matched' do
      expect(request_path("/plain/\xFF").first).to eq(404)
    end

    it 'recognizes a UTF-8 path' do
      expect(app.recognize_path('/café/42'.b)).to be_a(Grape::Endpoint)
    end

    context 'when no route holds a non-ASCII literal' do
      let(:app) do
        Class.new(Grape::API) do
          get('/plain/:id') { "plain #{params[:id].valid_encoding?}" }
        end
      end

      it 'still routes a path whose bytes are not UTF-8' do
        expect(request_path("/plain/\xFF")).to eq([200, 'plain false'])
      end
    end
  end

  # When no route for the request's method matches its path, the router answers
  # 405 if a route for another method does, and 404 otherwise. It only tries the
  # paths the method has no route on, since the others share a pattern with a
  # route that has just missed -- so these cover a path with no route for the
  # method, a covered path whose pattern overlaps an uncovered one, and methods
  # with no routes at all, for which every path is still a candidate.
  describe 'answering a path no route for the method matches' do
    let(:app) do
      Class.new(Grape::API) do
        format :json
        get('/items') { 'index' }
        post('/items') { 'create' }
        get('/items/:id') { 'show' }
        put('/items/:id') { 'update' }
        delete('/items/:id') { 'destroy' }
        # Digits only, so /users/me misses it and reaches the POST-only path.
        get('/users/:id', requirements: { id: /\d+/ }) { 'user' }
        post('/users/me') { 'me' }
      end
    end

    it 'answers 405 from a path the method has no route on' do
      post '/items/1'

      expect(last_response.status).to eq(405)
      expect(last_response.headers['Allow']).to eq('OPTIONS, GET, PUT, DELETE, HEAD')
    end

    it 'answers 405 from an uncovered path when a covered one overlaps it' do
      get '/users/me'

      expect(last_response.status).to eq(405)
      expect(last_response.headers['Allow']).to eq('OPTIONS, POST')
    end

    it 'answers 405 to a method that has no routes at all' do
      patch '/items/1'

      expect(last_response.status).to eq(405)
      expect(last_response.headers['Allow']).to eq('OPTIONS, GET, PUT, DELETE, HEAD')
    end

    it 'answers OPTIONS for a path' do
      options '/items/1'

      expect(last_response.status).to eq(204)
      expect(last_response.headers['Allow']).to eq('OPTIONS, GET, PUT, DELETE, HEAD')
    end

    it 'answers 404 to a path no route matches' do
      get '/nothing/here'
      expect(last_response.status).to eq(404)

      post '/nothing/here'
      expect(last_response.status).to eq(404)
    end

    context 'when every path has a route for the method' do
      let(:app) do
        Class.new(Grape::API) do
          get('/items') { 'index' }
          get('/items/:id') { 'show' }
          delete('/items/:id') { 'destroy' }
        end
      end

      it 'answers 404 to a path no route matches' do
        get '/nothing/here'

        expect(last_response.status).to eq(404)
      end
    end
  end
end
