# frozen_string_literal: true

# A method with enough routes is matched only against the routes that can
# match a request's path, told apart by one of its literal segments. Each
# example routes a request that narrowing could send to the wrong route, or to
# none.
describe Grape::Router::RouteBuckets do
  def route_for(path)
    get path
    expect(last_response.status).to eq(200)
    JSON.parse(last_response.body)
  end

  context 'with path versioning and a JSON format' do
    let(:app) do
      Class.new(Grape::API) do
        prefix :api
        format :json
        version 'v1', using: :path

        get('/:anything/first') { { route: 'anything first' } }
        10.times do |i|
          get("/resource#{i}") { { route: "index #{i}" } }
          get("/resource#{i}/:id") { { route: "show #{i}", id: params[:id] } }
        end
        get('/v1.2/items/:id') { { route: 'dotted literal' } }
        get('/proxy', anchor: false) { { route: 'unanchored' } }
        get('/files/*path') { { route: 'files', path: params[:path] } }
        get('/:slug') { { route: 'slug', slug: params[:slug] } }
      end
    end

    it 'routes a request to the route named by its segment' do
      expect(route_for('/api/v1/resource7/42')).to eq('route' => 'show 7', 'id' => '42')
    end

    it 'routes a request whose later segment spells the segment of another route' do
      expect(route_for('/api/v1/resource1/resource0')).to eq('route' => 'show 1', 'id' => 'resource0')
    end

    it 'prefers an earlier route whose segment is a param' do
      expect(route_for('/api/v1/resource1/first')).to eq('route' => 'anything first')
    end

    it 'falls back to the routes whose segment is a param when no route names it' do
      expect(route_for('/api/v1/unknown')).to eq('route' => 'slug', 'slug' => 'unknown')
    end

    it 'routes a segment spelled with a percent-encoding' do
      expect(route_for('/api/v1/%72esource7/42')).to eq('route' => 'show 7', 'id' => '42')
    end

    it 'routes a segment followed by the format extension' do
      expect(route_for('/api/v1/resource7.json')).to eq('route' => 'index 7')
    end

    it 'captures a param followed by the format extension' do
      expect(route_for('/api/v1/resource7/42.json')).to eq('route' => 'show 7', 'id' => '42')
    end

    it 'routes a literal segment holding a dot' do
      expect(route_for('/api/v1/v1.2/items/42')).to eq('route' => 'dotted literal')
    end

    it 'routes an unanchored route on a path running on from its last segment' do
      expect(route_for('/api/v1/proxyextra')).to eq('route' => 'unanchored')
    end

    it 'routes a splat route on a path running on from the segment ahead of its splat' do
      expect(route_for('/api/v1/filesextra')).to eq('route' => 'files', 'path' => 'extra')
    end
  end

  context 'with a param whose requirement spans a slash ahead of the literal' do
    let(:app) do
      Class.new(Grape::API) do
        format :json
        10.times do |i|
          get("/:tenant/resource#{i}/:id", requirements: { tenant: %r{[^/]+/[^/]+} }) do
            { route: "show #{i}", tenant: params[:tenant] }
          end
        end
      end
    end

    it 'routes a request whose param covers two segments' do
      expect(route_for('/acme/eu/resource3/42')).to eq('route' => 'show 3', 'tenant' => 'acme/eu')
    end
  end

  context 'when the routes are told apart by their first segment' do
    let(:app) do
      Class.new(Grape::API) do
        format :json
        10.times do |i|
          get("/resource#{i}/:id") { { route: "show #{i}" } }
        end
      end
    end

    it 'answers the root path as one no route matched' do
      get '/'

      expect(last_response.status).to eq(404)
    end
  end

  context 'with methods whose routes line up position for position' do
    let(:app) do
      Class.new(Grape::API) do
        format :json
        10.times do |i|
          get("/resource#{i}/:id") { { route: "show #{i}" } }
          post("/resource#{i}/:id/items") { { route: "add item #{i}" } }
        end
      end
    end

    it 'matches each method against its own routes' do
      post '/resource3/42/items'

      expect(last_response.status).to eq(201)
      expect(JSON.parse(last_response.body)).to eq('route' => 'add item 3')
    end
  end
end
