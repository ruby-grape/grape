# frozen_string_literal: true

require 'shared/versioning_examples'

describe Grape::API do
  subject { Class.new(described_class) }

  let(:app) { subject }

  describe '.prefix' do
    it 'routes root through with the prefix' do
      subject.prefix 'awesome/sauce'
      subject.get do
        'Hello there.'
      end

      get 'awesome/sauce/'
      expect(last_response).to be_successful
      expect(last_response.body).to eql 'Hello there.'
    end

    it 'routes through with the prefix' do
      subject.prefix 'awesome/sauce'
      subject.get :hello do
        'Hello there.'
      end

      get 'awesome/sauce/hello'
      expect(last_response.body).to eql 'Hello there.'

      get '/hello'
      expect(last_response).to be_not_found
    end

    it 'supports OPTIONS' do
      subject.prefix 'awesome/sauce'
      subject.get do
        'Hello there.'
      end

      options 'awesome/sauce'
      expect(last_response).to be_no_content
      expect(last_response.body).to be_blank
    end

    it 'disallows POST' do
      subject.prefix 'awesome/sauce'
      subject.get

      post 'awesome/sauce'
      expect(last_response).to be_method_not_allowed
    end
  end

  describe '.version' do
    context 'when defined' do
      it 'returns version value' do
        subject.version 'v1'
        expect(subject.version).to eq('v1')
      end
    end

    context 'when not defined' do
      it 'returns nil' do
        expect(subject.version).to be_nil
      end
    end
  end

  describe '.version using path' do
    it_behaves_like 'versioning' do
      let(:macro_options) do
        {
          using: :path
        }
      end
    end
  end

  describe '.version using param' do
    it_behaves_like 'versioning' do
      let(:macro_options) do
        {
          using: :param,
          parameter: 'apiver'
        }
      end
    end
  end

  describe '.version using header' do
    it_behaves_like 'versioning' do
      let(:macro_options) do
        {
          using: :header,
          vendor: 'mycompany',
          format: 'json'
        }
      end
    end
  end

  describe '.version using accept_version_header' do
    it_behaves_like 'versioning' do
      let(:macro_options) do
        {
          using: :accept_version_header
        }
      end
    end
  end

  describe '.represent' do
    it 'requires a :with option' do
      expect { subject.represent Object, {} }.to raise_error(Grape::Exceptions::InvalidWithOptionForRepresent)
    end

    it 'adds the association to the :representations setting' do
      klass = Class.new
      subject.represent Object, with: klass
      expect(subject.namespace_stackable_with_hash(:representations)[Object]).to eq(klass)
    end
  end

  describe '.namespace' do
    it 'is retrievable and converted to a path' do
      internal_namespace = nil
      subject.namespace :awesome do
        internal_namespace = namespace
      end
      expect(internal_namespace).to eql('/awesome')
    end

    it 'comes after the prefix and version' do
      subject.prefix :rad
      subject.version 'v1', using: :path

      subject.namespace :awesome do
        get('/hello') { 'worked' }
      end

      get '/rad/v1/awesome/hello'
      expect(last_response.body).to eq('worked')
    end

    it 'cancels itself after the block is over' do
      internal_namespace = nil
      subject.namespace :awesome do
        internal_namespace = namespace
      end
      expect(subject.namespace).to eql('/')
    end

    it 'is stackable' do
      internal_namespace = nil
      internal_second_namespace = nil
      subject.namespace :awesome do
        internal_namespace = namespace
        namespace :rad do
          internal_second_namespace = namespace
        end
      end
      expect(internal_namespace).to eq('/awesome')
      expect(internal_second_namespace).to eq('/awesome/rad')
    end

    it 'accepts path segments correctly' do
      inner_namespace = nil
      subject.namespace :members do
        namespace '/:member_id' do
          inner_namespace = namespace
          get '/' do
            params[:member_id]
          end
        end
      end
      get '/members/23'
      expect(last_response.body).to eq('23')
      expect(inner_namespace).to eq('/members/:member_id')
    end

    it 'is callable with nil just to push onto the stack' do
      subject.namespace do
        version 'v2', using: :path
        get('/hello') { 'inner' }
      end
      subject.get('/hello') { 'outer' }

      get '/v2/hello'
      expect(last_response.body).to eq('inner')
      get '/hello'
      expect(last_response.body).to eq('outer')
    end

    %w[group resource resources segment].each do |als|
      it "`.#{als}` is an alias" do
        inner_namespace = nil
        subject.send(als, :awesome) do
          inner_namespace = namespace
        end
        expect(inner_namespace).to eq '/awesome'
      end
    end
  end

  describe '.call' do
    context 'it does not add to the app setup' do
      it 'calls the app' do
        expect(subject).not_to receive(:add_setup)
        subject.call({})
      end
    end
  end

  describe '.route_param' do
    it 'adds a parameterized route segment namespace' do
      subject.namespace :users do
        route_param :id do
          get do
            params[:id]
          end
        end
      end

      get '/users/23'
      expect(last_response.body).to eq('23')
    end

    it 'defines requirements with a single hash' do
      subject.namespace :users do
        route_param :id, requirements: /[0-9]+/ do
          get do
            params[:id]
          end
        end
      end

      get '/users/michael'
      expect(last_response).to be_not_found
      get '/users/23'
      expect(last_response).to be_successful
    end

    context 'with param type definitions' do
      it 'is used by passing to options' do
        subject.namespace :route_param do
          route_param :foo, type: Integer do
            get { params.to_json }
          end
        end
        get '/route_param/1234'
        expect(last_response.body).to eq('{"foo":1234}')
      end
    end
  end

  describe '.route' do
    it 'allows for no path' do
      subject.namespace :votes do
        get do
          'Votes'
        end
        post do
          'Created a Vote'
        end
      end

      get '/votes'
      expect(last_response.body).to eql 'Votes'
      post '/votes'
      expect(last_response.body).to eql 'Created a Vote'
    end

    it 'handles empty calls' do
      subject.get '/'
      get '/'
      expect(last_response.body).to eql ''
    end

    describe 'root routes should work with' do
      before do
        subject.format :txt
        subject.content_type :json, 'application/json'
        subject.formatter :json, ->(object, _env) { object }
        def subject.enable_root_route!
          get('/') { 'root' }
        end
      end

      shared_examples_for 'a root route' do
        it 'returns root' do
          expect(last_response.body).to eql 'root'
        end
      end

      describe 'path versioned APIs' do
        before do
          subject.version version, using: :path
          subject.enable_root_route!
        end

        context 'when a single version provided' do
          let(:version) { 'v1' }

          context 'without a format' do
            before do
              versioned_get '/', 'v1', using: :path
            end

            it_behaves_like 'a root route'
          end

          context 'with a format' do
            before do
              get '/v1/.json'
            end

            it_behaves_like 'a root route'
          end
        end

        context 'when array of versions provided' do
          let(:version) { %w[v1 v2] }

          context 'when v1' do
            before do
              versioned_get '/', 'v1', using: :path
            end

            it_behaves_like 'a root route'
          end

          context 'when v2' do
            before do
              versioned_get '/', 'v2', using: :path
            end

            it_behaves_like 'a root route'
          end
        end
      end

      context 'when header versioned APIs' do
        before do
          subject.version 'v1', using: :header, vendor: 'test'
          subject.enable_root_route!
          versioned_get '/', 'v1', using: :header, vendor: 'test'
        end

        it_behaves_like 'a root route'
      end

      context 'when header versioned APIs with multiple headers' do
        before do
          subject.version %w[v1 v2], using: :header, vendor: 'test'
          subject.enable_root_route!
        end

        context 'when v1' do
          before do
            versioned_get '/', 'v1', using: :header, vendor: 'test'
          end

          it_behaves_like 'a root route'
        end

        context 'when v2' do
          before do
            versioned_get '/', 'v2', using: :header, vendor: 'test'
          end

          it_behaves_like 'a root route'
        end
      end

      context 'param versioned APIs' do
        before do
          subject.version 'v1', using: :param
          subject.enable_root_route!
          versioned_get '/', 'v1', using: :param
        end

        it_behaves_like 'a root route'
      end

      context 'when Accept-Version header versioned APIs' do
        before do
          subject.version 'v1', using: :accept_version_header
          subject.enable_root_route!
          versioned_get '/', 'v1', using: :accept_version_header
        end

        it_behaves_like 'a root route'
      end

      context 'unversioned APIss' do
        before do
          subject.enable_root_route!
          get '/'
        end

        it_behaves_like 'a root route'
      end
    end

    it 'allows for multiple paths' do
      subject.get(['/abc', '/def']) do
        'foo'
      end

      get '/abc'
      expect(last_response.body).to eql 'foo'
      get '/def'
      expect(last_response.body).to eql 'foo'
    end

    context 'format' do
      before do
        dummy_class = Class.new do
          def to_json(*_rest)
            'abc'
          end

          def to_txt
            'def'
          end
        end

        subject.get('/abc') do
          dummy_class.new
        end
      end

      it 'allows .json' do
        get '/abc.json'
        expect(last_response).to be_successful
        expect(last_response.body).to eql 'abc' # json-encoded symbol
      end

      it 'allows .txt' do
        get '/abc.txt'
        expect(last_response).to be_successful
        expect(last_response.body).to eql 'def' # raw text
      end
    end

    it 'allows for format without corrupting a param' do
      subject.get('/:id') do
        { 'id' => params[:id] }
      end

      get '/awesome.json'
      expect(last_response.body).to eql '{"id":"awesome"}'
    end

    it 'allows for format in namespace with no path' do
      subject.namespace :abc do
        get do
          ['json']
        end
      end

      get '/abc.json'
      expect(last_response.body).to eql '["json"]'
    end

    it 'allows for multiple verbs' do
      subject.route(%i[get post], '/abc') do
        'hiya'
      end

      subject.endpoints.first.routes.each do |route|
        expect(route.path).to eql '/abc(.:format)'
      end

      get '/abc'
      expect(last_response.body).to eql 'hiya'
      post '/abc'
      expect(last_response.body).to eql 'hiya'
    end

    objects = ['string', :symbol, 1, -1.1, {}, [], true, false, nil].freeze
    %i[put post].each do |verb|
      context verb.to_s do
        objects.each do |object|
          it "allows a(n) #{object.class} json object in params" do
            subject.format :json
            subject.send(verb) do
              env[Grape::Env::API_REQUEST_BODY]
            end
            send verb, '/', Grape::Json.dump(object), 'CONTENT_TYPE' => 'application/json'
            expect(last_response.status).to eq(verb == :post ? 201 : 200)
            expect(last_response.body).to eql Grape::Json.dump(object)
            expect(last_request.params).to eql({})
          end

          it 'stores input in api.request.input' do
            subject.format :json
            subject.send(verb) do
              env[Grape::Env::API_REQUEST_INPUT]
            end
            send verb, '/', Grape::Json.dump(object), 'CONTENT_TYPE' => 'application/json'
            expect(last_response.status).to eq(verb == :post ? 201 : 200)
            expect(last_response.body).to eql Grape::Json.dump(object).to_json
          end

          context 'chunked transfer encoding' do
            it 'stores input in api.request.input' do
              subject.format :json
              subject.send(verb) do
                env[Grape::Env::API_REQUEST_INPUT]
              end
              send verb, '/', Grape::Json.dump(object), 'CONTENT_TYPE' => 'application/json', Grape::Http::Headers::HTTP_TRANSFER_ENCODING => 'chunked'
              expect(last_response.status).to eq(verb == :post ? 201 : 200)
              expect(last_response.body).to eql Grape::Json.dump(object).to_json
            end
          end
        end
      end
    end

    it 'allows for multipart paths' do
      subject.route(%i[get post], '/:id/first') do
        'first'
      end

      subject.route(%i[get post], '/:id') do
        'ola'
      end
      subject.route(%i[get post], '/:id/first/second') do
        'second'
      end

      get '/1'
      expect(last_response.body).to eql 'ola'
      post '/1'
      expect(last_response.body).to eql 'ola'
      get '/1/first'
      expect(last_response.body).to eql 'first'
      post '/1/first'
      expect(last_response.body).to eql 'first'
      get '/1/first/second'
      expect(last_response.body).to eql 'second'
    end

    it 'allows for :any as a verb' do
      subject.route(:any, '/abc') do
        'lol'
      end

      %w[get post put delete options patch].each do |m|
        send(m, '/abc')
        expect(last_response.body).to eql 'lol'
      end
    end

    it 'allows for catch-all in a namespace' do
      subject.namespace :nested do
        get do
          'root'
        end

        get 'something' do
          'something'
        end

        route :any, '*path' do
          'catch-all'
        end
      end

      get 'nested'
      expect(last_response.body).to eql 'root'

      get 'nested/something'
      expect(last_response.body).to eql 'something'

      get 'nested/missing'
      expect(last_response.body).to eql 'catch-all'

      post 'nested'
      expect(last_response.body).to eql 'catch-all'

      post 'nested/something'
      expect(last_response.body).to eql 'catch-all'
    end

    verbs = %w[post get head delete put options patch]
    verbs.each do |verb|
      it "allows and properly constrain a #{verb.upcase} method" do
        subject.send(verb, '/example') do
          verb
        end
        send(verb, '/example')
        expect(last_response.body).to eql verb == 'head' ? '' : verb
        # Call it with all methods other than the properly constrained one.
        (verbs - [verb]).each do |other_verb|
          send(other_verb, '/example')
          expected_rc = if other_verb == 'options' then 204
                        elsif other_verb == 'head' && verb == 'get' then 200
                        else
                          405
                        end
          expect(last_response.status).to eql expected_rc
        end
      end
    end

    it 'returns a 201 response code for POST by default' do
      subject.post('example') do
        'Created'
      end

      post '/example'
      expect(last_response).to be_created
      expect(last_response.body).to eql 'Created'
    end

    it 'returns a 405 for an unsupported method with an X-Custom-Header' do
      subject.before { header 'X-Custom-Header', 'foo' }
      subject.get 'example' do
        'example'
      end
      put '/example'
      expect(last_response).to be_method_not_allowed
      expect(last_response.body).to eql '405 Not Allowed'
      expect(last_response.headers['X-Custom-Header']).to eql 'foo'
    end

    it 'runs only the before filter on 405 bad method' do
      subject.namespace :example do
        before            { header 'X-Custom-Header', 'foo' }

        before_validation { raise 'before_validation filter should not run' }
        after_validation  { raise 'after_validation filter should not run' }
        after             { raise 'after filter should not run' }

        params { requires :only_for_get }
        get
      end

      post '/example'
      expect(last_response).to be_method_not_allowed
      expect(last_response.headers['X-Custom-Header']).to eql 'foo'
    end

    it 'runs before filter exactly once on 405 bad method' do
      already_run = false
      subject.namespace :example do
        before do
          raise 'before filter ran twice' if already_run

          already_run = true
          header 'X-Custom-Header', 'foo'
        end

        get
      end

      post '/example'
      expect(last_response).to be_method_not_allowed
      expect(last_response.headers['X-Custom-Header']).to eql 'foo'
    end

    it 'runs all filters and body with a custom OPTIONS method' do
      subject.namespace :example do
        before            { header 'X-Custom-Header-1', 'foo' }

        before_validation { header 'X-Custom-Header-2', 'foo' }
        after_validation  { header 'X-Custom-Header-3', 'foo' }
        after             { header 'X-Custom-Header-4', 'foo' }

        options { 'yup' }
        get
      end

      options '/example'
      expect(last_response).to be_successful
      expect(last_response.body).to eql 'yup'
      expect(last_response.headers['Allow']).to be_nil
      expect(last_response.headers['X-Custom-Header-1']).to eql 'foo'
      expect(last_response.headers['X-Custom-Header-2']).to eql 'foo'
      expect(last_response.headers['X-Custom-Header-3']).to eql 'foo'
      expect(last_response.headers['X-Custom-Header-4']).to eql 'foo'
    end

    context 'when format is xml' do
      it 'returns a 405 for an unsupported method' do
        subject.format :xml
        subject.get 'example' do
          'example'
        end

        put '/example'
        expect(last_response).to be_method_not_allowed
        expect(last_response.body).to eq <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <error>
            <message>405 Not Allowed</message>
          </error>
        XML
      end
    end

    context 'when accessing env' do
      it 'returns a 405 for an unsupported method' do
        subject.before do
          _customheader1 = headers['X-Custom-Header']
          _customheader2 = env['HTTP_X_CUSTOM_HEADER']
        end
        subject.get 'example' do
          'example'
        end
        put '/example'
        expect(last_response).to be_method_not_allowed
        expect(last_response.body).to eql '405 Not Allowed'
      end
    end

    specify '405 responses includes an Allow header specifying supported methods' do
      subject.get 'example' do
        'example'
      end
      subject.post 'example' do
        'example'
      end
      put '/example'
      expect(last_response.headers['Allow']).to eql 'OPTIONS, GET, POST, HEAD'
    end

    specify '405 responses includes an Content-Type header' do
      subject.get 'example' do
        'example'
      end
      subject.post 'example' do
        'example'
      end
      put '/example'
      expect(last_response.content_type).to eql 'text/plain'
    end

    describe 'adds an OPTIONS route that' do
      before do
        subject.before            { header 'X-Custom-Header', 'foo' }
        subject.before_validation { header 'X-Custom-Header-2', 'bar' }
        subject.after_validation  { header 'X-Custom-Header-3', 'baz' }
        subject.after             { header 'X-Custom-Header-4', 'bing' }
        subject.params { requires :only_for_get }
        subject.get 'example' do
          'example'
        end
        subject.route :any, '*path' do
          error! :not_found, 404
        end
        options '/example'
      end

      it 'returns a 204' do
        expect(last_response).to be_no_content
      end

      it 'has an empty body' do
        expect(last_response.body).to be_blank
      end

      it 'has an Allow header' do
        expect(last_response.headers['Allow']).to eql 'OPTIONS, GET, HEAD'
      end

      it 'calls before hook' do
        expect(last_response.headers['X-Custom-Header']).to eql 'foo'
      end

      it 'does not call before_validation hook' do
        expect(last_response.headers.key?('X-Custom-Header-2')).to be false
      end

      it 'does not call after_validation hook' do
        expect(last_response.headers.key?('X-Custom-Header-3')).to be false
      end

      it 'calls after hook' do
        expect(last_response.headers['X-Custom-Header-4']).to eq 'bing'
      end

      it 'has no Content-Type' do
        expect(last_response.content_type).to be_nil
      end

      it 'has no Content-Length' do
        expect(last_response.content_length).to be_nil
      end
    end

    describe 'when a resource routes by POST, GET, PATCH, PUT, and DELETE' do
      before do
        subject.namespace :example do
          get do
            'example'
          end

          patch do
            'example'
          end

          post do
            'example'
          end

          delete do
            'example'
          end

          put do
            'example'
          end
        end
        options '/example'
      end

      describe 'it adds an OPTIONS route for namespaced endpoints that' do
        it 'returns a 204' do
          expect(last_response).to be_no_content
        end

        it 'has an empty body' do
          expect(last_response.body).to be_blank
        end

        it 'has an Allow header' do
          expect(last_response.headers['Allow']).to eql 'OPTIONS, GET, PATCH, POST, DELETE, PUT, HEAD'
        end
      end
    end

    describe 'adds an OPTIONS route for namespaced endpoints that' do
      before do
        subject.before { header 'X-Custom-Header', 'foo' }
        subject.namespace :example do
          before { header 'X-Custom-Header-2', 'foo' }

          get :inner do
            'example/inner'
          end
        end
        options '/example/inner'
      end

      it 'returns a 204' do
        expect(last_response).to be_no_content
      end

      it 'has an empty body' do
        expect(last_response.body).to be_blank
      end

      it 'has an Allow header' do
        expect(last_response.headers['Allow']).to eql 'OPTIONS, GET, HEAD'
      end

      it 'calls the outer before filter' do
        expect(last_response.headers['X-Custom-Header']).to eql 'foo'
      end

      it 'calls the inner before filter' do
        expect(last_response.headers['X-Custom-Header-2']).to eql 'foo'
      end

      it 'has no Content-Type' do
        expect(last_response.content_type).to be_nil
      end

      it 'has no Content-Length' do
        expect(last_response.content_length).to be_nil
      end
    end

    describe 'adds a 405 Not Allowed route that' do
      before do
        subject.before { header 'X-Custom-Header', 'foo' }
        subject.post :example do
          'example'
        end
        get '/example'
      end

      it 'returns a 405' do
        expect(last_response).to be_method_not_allowed
      end

      it 'contains error message in body' do
        expect(last_response.body).to eq '405 Not Allowed'
      end

      it 'has an Allow header' do
        expect(last_response.headers['Allow']).to eql 'OPTIONS, POST'
      end

      it 'has a X-Custom-Header' do
        expect(last_response.headers['X-Custom-Header']).to eql 'foo'
      end
    end

    describe 'when hook behaviour is controlled by attributes on the route' do
      before do
        subject.before do
          error!('Access Denied', 401) unless route.options[:secret] == params[:secret]
        end

        subject.namespace 'example' do
          before do
            error!('Access Denied', 401) unless route.options[:namespace_secret] == params[:namespace_secret]
          end

          desc 'it gets with secret', secret: 'password'
          get { status(params[:id] == '504' ? 200 : 404) }

          desc 'it post with secret', secret: 'password', namespace_secret: 'namespace_password'
          post {}
        end
      end

      context 'when HTTP method is not defined' do
        let(:response) { delete('/example') }

        it 'responds with a 405 status' do
          expect(response).to be_method_not_allowed
        end
      end

      context 'when HTTP method is defined with attribute' do
        let(:response) { post('/example?secret=incorrect_password') }

        it 'responds with the defined error in the before hook' do
          expect(response).to be_unauthorized
        end
      end

      context 'when HTTP method is defined and the underlying before hook expectation is not met' do
        let(:response) { post('/example?secret=password&namespace_secret=wrong_namespace_password') }

        it 'ends up in the endpoint' do
          expect(response).to be_unauthorized
        end
      end

      context 'when HTTP method is defined and everything is like the before hooks expect' do
        let(:response) { post('/example?secret=password&namespace_secret=namespace_password') }

        it 'ends up in the endpoint' do
          expect(response).to be_created
        end
      end

      context 'when HEAD is called for the defined GET' do
        let(:response) { head('/example?id=504') }

        it 'responds with 401 because before expectations in before hooks are not met' do
          expect(response).to be_unauthorized
        end
      end

      context 'when HEAD is called for the defined GET' do
        let(:response) { head('/example?id=504&secret=password') }

        it 'responds with 200 because before hooks are not called' do
          expect(response).to be_successful
        end
      end
    end

    context 'allows HEAD on a GET request that' do
      before do
        subject.get 'example' do
          'example'
        end
        subject.route :any, '*path' do
          error! :not_found, 404
        end
        head '/example'
      end

      it 'returns a 200' do
        expect(last_response).to be_successful
      end

      it 'has an empty body' do
        expect(last_response.body).to eql ''
      end
    end

    it 'overwrites the default HEAD request' do
      subject.head 'example' do
        error! 'nothing to see here', 400
      end
      subject.get 'example' do
        'example'
      end
      head '/example'
      expect(last_response).to be_bad_request
    end
  end

  context 'do_not_route_head!' do
    before do
      subject.do_not_route_head!
      subject.get 'example' do
        'example'
      end
    end

    it 'options does not contain HEAD' do
      options '/example'
      expect(last_response).to be_no_content
      expect(last_response.body).to eql ''
      expect(last_response.headers['Allow']).to eql 'OPTIONS, GET'
    end

    it 'does not allow HEAD on a GET request' do
      head '/example'
      expect(last_response).to be_method_not_allowed
    end
  end

  context 'do_not_route_options!' do
    before do
      subject.do_not_route_options!
      subject.get 'example' do
        'example'
      end
    end

    it 'does not create an OPTIONS route' do
      options '/example'
      expect(last_response).to be_method_not_allowed
    end

    it 'does not include OPTIONS in Allow header' do
      options '/example'
      expect(last_response).to be_method_not_allowed
      expect(last_response.headers['Allow']).to eql 'GET, HEAD'
    end
  end

  describe '.compile!' do
    let(:base_instance) { app.base_instance }

    before do
      allow(base_instance).to receive(:compile!).and_return(:compiled!)
    end

    it 'returns compiled!' do
      expect(app.send(:compile!)).to eq(:compiled!)
    end
  end

  # NOTE: this method is required to preserve the ability of pre-mounting
  # the root API into a namespace, it may be deprecated in the future.
  describe 'instance_for_rack' do
    context 'when the app was not mounted' do
      it 'returns the base_instance' do
        expect(app.send(:instance_for_rack)).to eq app.base_instance
      end
    end

    context 'when the app was mounted' do
      it 'returns the first mounted instance' do
        mounted_app = app
        Class.new(described_class) do
          namespace 'new_namespace' do
            mount mounted_app
          end
        end
        expect(app.send(:instance_for_rack)).to eq app.send(:mounted_instances).first
      end
    end
  end

  describe 'filters' do
    it 'adds a before filter' do
      subject.before { @foo = 'first'  }
      subject.before { @bar = 'second' }
      subject.get '/' do
        "#{@foo} #{@bar}"
      end

      get '/'
      expect(last_response.body).to eql 'first second'
    end

    it 'adds a before filter to current and child namespaces only' do
      subject.get '/' do
        "root - #{instance_variable_defined?(:@foo) ? @foo : nil}"
      end
      subject.namespace :blah do
        before { @foo = 'foo' }

        get '/' do
          "blah - #{@foo}"
        end

        namespace :bar do
          get '/' do
            "blah - bar - #{@foo}"
          end
        end
      end

      get '/'
      expect(last_response.body).to eql 'root - '
      get '/blah'
      expect(last_response.body).to eql 'blah - foo'
      get '/blah/bar'
      expect(last_response.body).to eql 'blah - bar - foo'
    end

    it 'adds a after_validation filter' do
      subject.after_validation { @foo = "first #{params[:id]}:#{params[:id].class}" }
      subject.after_validation { @bar = 'second' }
      subject.params do
        requires :id, type: Integer
      end
      subject.get '/' do
        "#{@foo} #{@bar}"
      end

      get '/', id: '32'
      expect(last_response.body).to eql "first 32:#{integer_class_name} second"
    end

    it 'adds a after filter' do
      m = double('after mock')
      subject.after { m.do_something! }
      subject.after { m.do_something! }
      subject.get '/' do
        @var ||= 'default'
      end

      expect(m).to receive(:do_something!).twice
      get '/'
      expect(last_response.body).to eql 'default'
    end

    it 'calls all filters when validation passes' do
      a = double('before mock')
      b = double('before_validation mock')
      c = double('after_validation mock')
      d = double('after mock')

      subject.params do
        requires :id, type: Integer
      end
      subject.resource ':id' do
        before { a.do_something! }

        before_validation { b.do_something! }
        after_validation { c.do_something! }
        after { d.do_something! }

        get do
          'got it'
        end
      end

      expect(a).to receive(:do_something!).once
      expect(b).to receive(:do_something!).once
      expect(c).to receive(:do_something!).once
      expect(d).to receive(:do_something!).once

      get '/123'
      expect(last_response).to be_successful
      expect(last_response.body).to eql 'got it'
    end

    it 'calls only before filters when validation fails' do
      a = double('before mock')
      b = double('before_validation mock')
      c = double('after_validation mock')
      d = double('after mock')

      subject.params do
        requires :id, type: Integer, values: [1, 2, 3]
      end
      subject.resource ':id' do
        before { a.do_something! }

        before_validation { b.do_something! }
        after_validation { c.do_something! }
        after { d.do_something! }

        get do
          'got it'
        end
      end

      expect(a).to receive(:do_something!).once
      expect(b).to receive(:do_something!).once
      expect(c).to receive(:do_something!).exactly(0).times
      expect(d).to receive(:do_something!).exactly(0).times

      get '/4'
      expect(last_response).to be_bad_request
      expect(last_response.body).to eql 'id does not have a valid value'
    end

    it 'calls filters in the correct order' do
      i = 0
      a = double('before mock')
      b = double('before_validation mock')
      c = double('after_validation mock')
      d = double('after mock')

      subject.params do
        requires :id, type: Integer
      end
      subject.resource ':id' do
        before { a.here(i += 1) }

        before_validation { b.here(i += 1) }
        after_validation { c.here(i += 1) }
        after { d.here(i += 1) }

        get do
          'got it'
        end
      end

      expect(a).to receive(:here).with(1).once
      expect(b).to receive(:here).with(2).once
      expect(c).to receive(:here).with(3).once
      expect(d).to receive(:here).with(4).once

      get '/123'
      expect(last_response).to be_successful
      expect(last_response.body).to eql 'got it'
    end
  end

  context 'format' do
    before do
      subject.get('/foo') { 'bar' }
    end

    it 'sets content type for txt format' do
      get '/foo'
      expect(last_response.content_type).to eq('text/plain')
    end

    it 'does not set Cache-Control' do
      get '/foo'
      expect(last_response.headers[Rack::CACHE_CONTROL]).to be_nil
    end

    it 'sets content type for xml' do
      get '/foo.xml'
      expect(last_response.content_type).to eq('application/xml')
    end

    it 'sets content type for json' do
      get '/foo.json'
      expect(last_response.content_type).to eq('application/json')
    end

    it 'sets content type for serializable hash format' do
      get '/foo.serializable_hash'
      expect(last_response.content_type).to eq('application/json')
    end

    it 'sets content type for binary format' do
      get '/foo.binary'
      expect(last_response.content_type).to eq('application/octet-stream')
    end

    it 'returns raw data when content type binary' do
      image_filename = 'grape.png'
      file = File.binread(image_filename)
      subject.format :binary
      subject.get('/binary_file') { File.binread(image_filename) }
      get '/binary_file'
      expect(last_response.content_type).to eq('application/octet-stream')
      expect(last_response.body).to eq(file)
    end

    it 'returns the content of the file with file' do
      file_content = 'This is some file content'
      test_file = Tempfile.new('test')
      test_file.write file_content
      test_file.rewind

      subject.get('/file') { stream test_file }
      get '/file'
      expect(last_response.content_length).to eq(25)
      expect(last_response.content_type).to eq('text/plain')
      expect(last_response.body).to eq(file_content)
    end

    it 'streams the content of the file with stream' do
      test_stream = Enumerator.new do |blk|
        blk.yield 'This is some'
        blk.yield ' file content'
      end

      subject.use Gem::Version.new(Rack.release) < Gem::Version.new('3') ? Rack::Chunked : ChunkedResponse
      subject.get('/stream') { stream test_stream }
      get '/stream', {}, 'HTTP_VERSION' => 'HTTP/1.1', Rack::SERVER_PROTOCOL => 'HTTP/1.1'

      expect(last_response.content_type).to eq('text/plain')
      expect(last_response.content_length).to be_nil
      expect(last_response.headers[Rack::CACHE_CONTROL]).to eq('no-cache')
      expect(last_response.headers[Grape::Http::Headers::TRANSFER_ENCODING]).to eq('chunked')

      expect(last_response.body).to eq("c\r\nThis is some\r\nd\r\n file content\r\n0\r\n\r\n")
    end

    it 'sets content type for error' do
      subject.get('/error') { error!('error in plain text', 500) }
      get '/error'
      expect(last_response.content_type).to eql 'text/plain'
    end

    it 'sets content type for json error' do
      subject.format :json
      subject.get('/error') { error!('error in json', 500) }
      get '/error.json'
      expect(last_response).to be_server_error
      expect(last_response.content_type).to eql 'application/json'
    end

    it 'sets content type for xml error' do
      subject.format :xml
      subject.get('/error') { error!('error in xml', 500) }
      get '/error'
      expect(last_response).to be_server_error
      expect(last_response.content_type).to eql 'application/xml'
    end

    it 'includes extension in format' do
      subject.get(':id') { params[:format] }

      get '/baz.bar'
      expect(last_response).to be_successful
      expect(last_response.body).to eq 'bar'
    end

    it 'does not include extension in id' do
      subject.format :json
      subject.get(':id') { params }

      get '/baz.bar'
      expect(last_response).to be_not_found
    end

    context 'with a custom content_type' do
      before do
        subject.content_type :custom, 'application/custom'
        subject.formatter :custom, ->(_object, _env) { 'custom' }

        subject.get('/custom') { 'bar' }
        subject.get('/error') { error!('error in custom', 500) }
      end

      it 'sets content type' do
        get '/custom.custom'
        expect(last_response.content_type).to eql 'application/custom'
      end

      it 'sets content type for error' do
        get '/error.custom'
        expect(last_response.content_type).to eql 'application/custom'
      end
    end

    context 'env["api.format"]' do
      before do
        ct = content_type
        subject.post 'attachment' do
          filename = params[:file][:filename]
          content_type ct
          env[Grape::Env::API_FORMAT] = :binary # there's no formatter for :binary, data will be returned "as is"
          header 'Content-Disposition', "attachment; filename*=UTF-8''#{CGI.escape(filename)}"
          params[:file][:tempfile].read
        end
      end

      context 'when image/png' do
        let(:content_type) { 'image/png' }

        %w[/attachment.png attachment].each do |url|
          it "uploads and downloads a PNG file via #{url}" do
            image_filename = 'grape.png'
            post url, file: Rack::Test::UploadedFile.new(image_filename, content_type, true)
            expect(last_response).to be_created
            expect(last_response.content_type).to eq(content_type)
            expect(last_response.headers['Content-Disposition']).to eq("attachment; filename*=UTF-8''grape.png")
            File.open(image_filename, 'rb') do |io|
              expect(last_response.body).to eq io.read
            end
          end
        end
      end

      context 'when ruby file' do
        let(:content_type) { 'application/x-ruby' }

        it 'uploads and downloads a Ruby file' do
          filename = __FILE__
          post '/attachment.rb', file: Rack::Test::UploadedFile.new(filename, content_type, true)
          expect(last_response).to be_created
          expect(last_response.content_type).to eq(content_type)
          expect(last_response.headers['Content-Disposition']).to eq("attachment; filename*=UTF-8''api_spec.rb")
          File.open(filename, 'rb') do |io|
            expect(last_response.body).to eq io.read
          end
        end
      end
    end
  end

  context 'custom middleware' do
    let(:phony_middleware) do
      Class.new do
        def initialize(app, *args)
          @args = args
          @app = app
          @block = block_given? ? true : nil
        end

        def call(env)
          env['phony.args'] ||= []
          env['phony.args'] << @args
          env['phony.block'] = true if @block
          @app.call(env)
        end
      end
    end

    describe '.middleware' do
      it 'includes middleware arguments from settings' do
        subject.use phony_middleware, 'abc', 123
        expect(subject.middleware).to eql [[:use, phony_middleware, 'abc', 123]]
      end

      it 'includes all middleware from stacked settings' do
        subject.use phony_middleware, 123
        subject.use phony_middleware, 'abc'
        subject.use phony_middleware, 'foo'

        expect(subject.middleware).to eql [
          [:use, phony_middleware, 123],
          [:use, phony_middleware, 'abc'],
          [:use, phony_middleware, 'foo']
        ]
      end
    end

    describe '.use' do
      it 'adds middleware' do
        subject.use phony_middleware, 123
        expect(subject.middleware).to eql [[:use, phony_middleware, 123]]
      end

      it 'does not show up outside the namespace' do
        example = self
        inner_middleware = nil
        subject.use phony_middleware, 123
        subject.namespace :awesome do
          use example.phony_middleware, 'abc'
          inner_middleware = middleware
        end

        expect(subject.middleware).to eql [[:use, phony_middleware, 123]]
        expect(inner_middleware).to eql [[:use, phony_middleware, 123], [:use, phony_middleware, 'abc']]
      end

      it 'calls the middleware' do
        subject.use phony_middleware, 'hello'
        subject.get '/' do
          env['phony.args'].first.first
        end

        get '/'
        expect(last_response.body).to eql 'hello'
      end

      it 'adds a block if one is given' do
        block = -> {}
        subject.use phony_middleware, &block
        expect(subject.middleware).to eql [[:use, phony_middleware, block]]
      end

      it 'uses a block if one is given' do
        block = -> {}
        subject.use phony_middleware, &block
        subject.get '/' do
          env['phony.block'].inspect
        end

        get '/'
        expect(last_response.body).to eq('true')
      end

      it 'does not destroy the middleware settings on multiple runs' do
        block = -> {}
        subject.use phony_middleware, &block
        subject.get '/' do
          env['phony.block'].inspect
        end

        2.times do
          get '/'
          expect(last_response.body).to eq('true')
        end
      end

      it 'mounts behind error middleware' do
        m = Class.new(Grape::Middleware::Base) do
          def before
            throw :error, message: 'Caught in the Net', status: 400
          end
        end
        subject.use m
        subject.get '/' do
        end
        get '/'
        expect(last_response).to be_bad_request
        expect(last_response.body).to eq('Caught in the Net')
      end
    end

    describe '.insert_before' do
      it 'runs before a given middleware' do
        m = Class.new(Grape::Middleware::Base) do
          def call(env)
            env['phony.args'] ||= []
            env['phony.args'] << @options[:message]
            @app.call(env)
          end
        end

        subject.use phony_middleware, 'hello'
        subject.insert_before phony_middleware, m, message: 'bye'
        subject.get '/' do
          env['phony.args'].join(' ')
        end

        get '/'
        expect(last_response.body).to eql 'bye hello'
      end
    end

    describe '.insert_after' do
      it 'runs after a given middleware' do
        m = Class.new(Grape::Middleware::Base) do
          def call(env)
            env['phony.args'] ||= []
            env['phony.args'] << @options[:message]
            @app.call(env)
          end
        end

        subject.use phony_middleware, 'hello'
        subject.insert_after phony_middleware, m, message: 'bye'
        subject.get '/' do
          env['phony.args'].join(' ')
        end

        get '/'
        expect(last_response.body).to eql 'hello bye'
      end
    end

    describe '.insert' do
      it 'inserts middleware in a specific location in the stack' do
        m = Class.new(Grape::Middleware::Base) do
          def call(env)
            env['phony.args'] ||= []
            env['phony.args'] << @options[:message]
            @app.call(env)
          end
        end

        subject.use phony_middleware, 'bye'
        subject.insert 0, m, message: 'good'
        subject.insert 0, m, message: 'hello'
        subject.get '/' do
          env['phony.args'].join(' ')
        end

        get '/'
        expect(last_response.body).to eql 'hello good bye'
      end
    end
  end

  describe '.http_basic' do
    it 'protects any resources on the same scope' do
      subject.http_basic do |u, _p|
        u == 'allow'
      end
      subject.get(:hello) { 'Hello, world.' }
      get '/hello'
      expect(last_response).to be_unauthorized
      get '/hello', {}, 'HTTP_AUTHORIZATION' => encode_basic_auth('allow', 'whatever')
      expect(last_response).to be_successful
    end

    it 'is scopable' do
      subject.get(:hello) { 'Hello, world.' }
      subject.namespace :admin do
        http_basic do |u, _p|
          u == 'allow'
        end

        get(:hello) { 'Hello, world.' }
      end

      get '/hello'
      expect(last_response).to be_successful
      get '/admin/hello'
      expect(last_response).to be_unauthorized
    end

    it 'is callable via .auth as well' do
      subject.auth :http_basic do |u, _p|
        u == 'allow'
      end

      subject.get(:hello) { 'Hello, world.' }
      get '/hello'
      expect(last_response).to be_unauthorized
      get '/hello', {}, 'HTTP_AUTHORIZATION' => encode_basic_auth('allow', 'whatever')
      expect(last_response).to be_successful
    end

    it 'has access to the current endpoint' do
      basic_auth_context = nil

      subject.http_basic do |u, _p|
        basic_auth_context = self

        u == 'allow'
      end

      subject.get(:hello) { 'Hello, world.' }
      get '/hello', {}, 'HTTP_AUTHORIZATION' => encode_basic_auth('allow', 'whatever')
      expect(basic_auth_context).to be_a(Grape::Endpoint)
    end

    it 'has access to helper methods' do
      subject.helpers do
        def authorize(user, password)
          user == 'allow' && password == 'whatever'
        end
      end

      subject.http_basic do |u, p|
        authorize(u, p)
      end

      subject.get(:hello) { 'Hello, world.' }
      get '/hello', {}, 'HTTP_AUTHORIZATION' => encode_basic_auth('allow', 'whatever')
      expect(last_response).to be_successful
      get '/hello', {}, 'HTTP_AUTHORIZATION' => encode_basic_auth('disallow', 'whatever')
      expect(last_response).to be_unauthorized
    end

    it 'can set instance variables accessible to routes' do
      subject.http_basic do |u, _p|
        @hello = 'Hello, world.'

        u == 'allow'
      end

      subject.get(:hello) { @hello }
      get '/hello', {}, 'HTTP_AUTHORIZATION' => encode_basic_auth('allow', 'whatever')
      expect(last_response).to be_successful
      expect(last_response.body).to eql 'Hello, world.'
    end
  end

  describe '.logger' do
    it 'returns an instance of Logger class by default' do
      expect(subject.logger.class).to eql Logger
    end

    context 'with a custom logger' do
      subject do
        Class.new(described_class) do
          def self.io
            @io ||= StringIO.new
          end
          logger Logger.new(io)
        end
      end

      it 'exposes its interaface' do
        message = 'this will be logged'
        subject.logger.info message
        expect(subject.io.string).to include(message)
      end
    end

    it 'does not unnecessarily retain duplicate setup blocks' do
      subject.logger
      expect { subject.logger }.not_to change(subject.instance_variable_get(:@setup), :size)
    end
  end

  describe '.helpers' do
    it 'is accessible from the endpoint' do
      subject.helpers do
        def hello
          'Hello, world.'
        end
      end

      subject.get '/howdy' do
        hello
      end

      get '/howdy'
      expect(last_response.body).to eql 'Hello, world.'
    end

    it 'is scopable' do
      subject.helpers do
        def generic
          'always there'
        end
      end

      subject.namespace :admin do
        helpers do
          def secret
            'only in admin'
          end
        end

        get '/secret' do
          [generic, secret].join ':'
        end
      end

      subject.get '/generic' do
        [generic, respond_to?(:secret)].join ':'
      end

      get '/generic'
      expect(last_response.body).to eql 'always there:false'
      get '/admin/secret'
      expect(last_response.body).to eql 'always there:only in admin'
    end

    it 'is reopenable' do
      subject.helpers do
        def one
          1
        end
      end

      subject.helpers do
        def two
          2
        end
      end

      subject.get 'howdy' do
        [one, two]
      end

      expect { get '/howdy' }.not_to raise_error
    end

    it 'allows for modules' do
      mod = Module.new do
        def hello
          'Hello, world.'
        end
      end
      subject.helpers mod

      subject.get '/howdy' do
        hello
      end

      get '/howdy'
      expect(last_response.body).to eql 'Hello, world.'
    end

    it 'allows multiple calls with modules and blocks' do
      subject.helpers Module.new do
        def one
          1
        end
      end
      subject.helpers Module.new do
        def two
          2
        end
      end
      subject.helpers do
        def three
          3
        end
      end
      subject.get 'howdy' do
        [one, two, three]
      end
      expect { get '/howdy' }.not_to raise_error
    end
  end

  describe '.scope' do
    # TODO: refactor this to not be tied to versioning. How about a generic
    # .setting macro?
    it 'scopes the various settings' do
      subject.prefix 'new'

      subject.scope :legacy do
        prefix 'legacy'
        get '/abc' do
          'abc'
        end
      end

      subject.get '/def' do
        'def'
      end

      get '/new/abc'
      expect(last_response).to be_not_found
      get '/legacy/abc'
      expect(last_response).to be_successful
      get '/legacy/def'
      expect(last_response).to be_not_found
      get '/new/def'
      expect(last_response).to be_successful
    end
  end

  describe 'lifecycle' do
    let!(:lifecycle) { [] }
    let!(:standard_cycle) do
      %i[before before_validation after_validation api_call after finally]
    end

    let!(:validation_error) do
      %i[before before_validation finally]
    end

    let!(:errored_cycle) do
      %i[before before_validation after_validation api_call finally]
    end

    before do
      current_cycle = lifecycle

      subject.before do
        current_cycle << :before
      end

      subject.before_validation do
        current_cycle << :before_validation
      end

      subject.after_validation do
        current_cycle << :after_validation
      end

      subject.after do
        current_cycle << :after
      end

      subject.finally do
        current_cycle << :finally
      end
    end

    context 'when the api_call succeeds' do
      before do
        current_cycle = lifecycle

        subject.get 'api_call' do
          current_cycle << :api_call
        end
      end

      it 'follows the standard life_cycle' do
        get '/api_call'
        expect(lifecycle).to eq standard_cycle
      end
    end

    context 'when the api_call has a controlled error' do
      before do
        current_cycle = lifecycle

        subject.get 'api_call' do
          current_cycle << :api_call
          error!(:some_error)
        end
      end

      it 'follows the errored life_cycle (skips after)' do
        get '/api_call'
        expect(lifecycle).to eq errored_cycle
      end
    end

    context 'when the api_call has an exception' do
      before do
        current_cycle = lifecycle

        subject.get 'api_call' do
          current_cycle << :api_call
          raise StandardError
        end
      end

      it 'follows the errored life_cycle (skips after)' do
        expect { get '/api_call' }.to raise_error(StandardError)
        expect(lifecycle).to eq errored_cycle
      end
    end

    context 'when the api_call fails validation' do
      before do
        current_cycle = lifecycle

        subject.params do
          requires :some_param, type: String
        end

        subject.get 'api_call' do
          current_cycle << :api_call
        end
      end

      it 'follows the failed_validation cycle (skips after_validation, api_call & after)' do
        get '/api_call'
        expect(lifecycle).to eq validation_error
      end
    end
  end

  describe '.finally' do
    let!(:code) { { has_executed: false } }
    let(:block_to_run) do
      code_to_execute = code
      proc do
        code_to_execute[:has_executed] = true
      end
    end

    context 'when the ensure block has no exceptions' do
      before { subject.finally(&block_to_run) }

      context 'when no API call is made' do
        it 'has not executed the ensure code' do
          expect(code[:has_executed]).to be false
        end
      end

      context 'when no errors occurs' do
        before do
          subject.get '/no_exceptions' do
            'success'
          end
        end

        it 'executes the ensure code' do
          get '/no_exceptions'
          expect(last_response.body).to eq 'success'
          expect(code[:has_executed]).to be true
        end

        context 'with a helper' do
          let(:block_to_run) do
            code_to_execute = code
            proc do
              code_to_execute[:value] = some_helper
            end
          end

          before do
            subject.helpers do
              def some_helper
                'some_value'
              end
            end

            subject.get '/with_helpers' do
              'success'
            end
          end

          it 'has access to the helper' do
            get '/with_helpers'
            expect(code[:value]).to eq 'some_value'
          end
        end
      end

      context 'when an unhandled occurs inside the API call' do
        before do
          subject.get '/unhandled_exception' do
            raise StandardError
          end
        end

        it 'executes the ensure code' do
          expect { get '/unhandled_exception' }.to raise_error StandardError
          expect(code[:has_executed]).to be true
        end
      end

      context 'when a handled error occurs inside the API call' do
        before do
          subject.rescue_from(StandardError) { error! 'handled' }
          subject.get '/handled_exception' do
            raise StandardError
          end
        end

        it 'executes the ensure code' do
          get '/handled_exception'
          expect(code[:has_executed]).to be true
          expect(last_response.body).to eq 'handled'
        end
      end
    end
  end

  describe '.rescue_from' do
    it 'does not rescue errors when rescue_from is not set' do
      subject.get '/exception' do
        raise 'rain!'
      end
      expect { get '/exception' }.to raise_error(RuntimeError, 'rain!')
    end

    it 'uses custom helpers defined by using #helpers method' do
      subject.helpers do
        def custom_error!(name)
          error! "hello #{name}"
        end
      end
      subject.rescue_from(ArgumentError) { custom_error! :bob }
      subject.get '/custom_error' do
        raise ArgumentError
      end
      get '/custom_error'
      expect(last_response.body).to eq 'hello bob'
    end

    context 'with multiple apis' do
      let(:a) do
        Class.new(described_class) do
          namespace :a do
            helpers do
              def foo
                error!('foo', 401)
              end
            end

            rescue_from(:all) { foo }

            get { raise 'boo' }
          end
        end
      end
      let(:b) do
        Class.new(described_class) do
          namespace :b do
            helpers do
              def foo
                error!('bar', 401)
              end
            end

            rescue_from(:all) { foo }

            get { raise 'boo' }
          end
        end
      end

      before do
        subject.mount a
        subject.mount b
      end

      it 'avoids polluting global namespace' do
        get '/a'
        expect(last_response.body).to eq('foo')
        get '/b'
        expect(last_response.body).to eq('bar')
        get '/a'
        expect(last_response.body).to eq('foo')
      end
    end

    it 'rescues all errors if rescue_from :all is called' do
      subject.rescue_from :all
      subject.get '/exception' do
        raise 'rain!'
      end
      get '/exception'
      expect(last_response).to be_server_error
      expect(last_response.body).to eq 'rain!'
    end

    it 'rescues all errors with a json formatter' do
      subject.format :json
      subject.default_format :json
      subject.rescue_from :all
      subject.get '/exception' do
        raise 'rain!'
      end
      get '/exception'
      expect(last_response).to be_server_error
      expect(last_response.body).to eq({ error: 'rain!' }.to_json)
    end

    it 'rescues only certain errors if rescue_from is called with specific errors' do
      subject.rescue_from ArgumentError
      subject.get('/rescued') { raise ArgumentError }
      subject.get('/unrescued') { raise 'beefcake' }

      get '/rescued'
      expect(last_response).to be_server_error

      expect { get '/unrescued' }.to raise_error(RuntimeError, 'beefcake')
    end

    it 'mimics default ruby "rescue" handler' do
      # The exception is matched to the rescue starting at the top, and matches only once

      subject.rescue_from ArgumentError do |e|
        error!(e, 402)
      end
      subject.rescue_from StandardError do |e|
        error!(e, 401)
      end

      subject.get('/child_of_standard_error') { raise ArgumentError }
      subject.get('/standard_error') { raise StandardError }

      get '/child_of_standard_error'
      expect(last_response.status).to be 402

      get '/standard_error'
      expect(last_response).to be_unauthorized
    end

    context 'CustomError subclass of Grape::Exceptions::Base' do
      before do
        stub_const('ApiSpec::CustomError', Class.new(Grape::Exceptions::Base))
      end

      it 'does not re-raise exceptions of type Grape::Exceptions::Base' do
        subject.get('/custom_exception') { raise ApiSpec::CustomError }

        expect { get '/custom_exception' }.not_to raise_error
      end

      it 'rescues custom grape exceptions' do
        subject.rescue_from ApiSpec::CustomError do |e|
          error!('New Error', e.status)
        end
        subject.get '/custom_error' do
          raise ApiSpec::CustomError.new(status: 400, message: 'Custom Error')
        end

        get '/custom_error'
        expect(last_response).to be_bad_request
        expect(last_response.body).to eq('New Error')
      end
    end

    it 'can rescue exceptions raised in the formatter' do
      formatter = double(:formatter)
      allow(formatter).to receive(:call) { raise StandardError }
      allow(Grape::Formatter).to receive(:formatter_for) { formatter }

      subject.rescue_from :all do |_e|
        error!('Formatter Error', 500)
      end
      subject.get('/formatter_exception') { 'Hello world' }

      get '/formatter_exception'
      expect(last_response).to be_server_error
      expect(last_response.body).to eq('Formatter Error')
    end

    context 'when rescue_from block returns an invalid response' do
      it 'returns a formatted response' do
        subject.rescue_from(:all) { 'error' }
        subject.get('/') { raise }
        get '/'
        expect(last_response).to be_server_error
        expect(last_response.body).to eql 'Invalid response'
      end
    end
  end

  describe '.rescue_from klass, block' do
    it 'rescues Exception' do
      subject.rescue_from RuntimeError do |e|
        error!("rescued from #{e.message}", 202)
      end
      subject.get '/exception' do
        raise 'rain!'
      end
      get '/exception'
      expect(last_response).to be_accepted
      expect(last_response.body).to eq('rescued from rain!')
    end

    context 'custom errors' do
      before do
        stub_const('ConnectionError', Class.new(RuntimeError))
        stub_const('DatabaseError', Class.new(RuntimeError))
        stub_const('CommunicationError', Class.new(StandardError))
      end

      it 'rescues an error via rescue_from :all' do
        subject.rescue_from :all do |e|
          error!("rescued from #{e.class.name}", 500)
        end
        subject.get '/exception' do
          raise ConnectionError
        end
        get '/exception'
        expect(last_response).to be_server_error
        expect(last_response.body).to eq('rescued from ConnectionError')
      end

      it 'rescues a specific error' do
        subject.rescue_from ConnectionError do |e|
          error!("rescued from #{e.class.name}", 500)
        end
        subject.get '/exception' do
          raise ConnectionError
        end
        get '/exception'
        expect(last_response).to be_server_error
        expect(last_response.body).to eq('rescued from ConnectionError')
      end

      it 'rescues a subclass of an error by default' do
        subject.rescue_from RuntimeError do |e|
          error!("rescued from #{e.class.name}", 500)
        end
        subject.get '/exception' do
          raise ConnectionError
        end
        get '/exception'
        expect(last_response).to be_server_error
        expect(last_response.body).to eq('rescued from ConnectionError')
      end

      it 'rescues multiple specific errors' do
        subject.rescue_from ConnectionError do |e|
          error!("rescued from #{e.class.name}", 500)
        end
        subject.rescue_from DatabaseError do |e|
          error!("rescued from #{e.class.name}", 500)
        end
        subject.get '/connection' do
          raise ConnectionError
        end
        subject.get '/database' do
          raise DatabaseError
        end
        get '/connection'
        expect(last_response).to be_server_error
        expect(last_response.body).to eq('rescued from ConnectionError')
        get '/database'
        expect(last_response).to be_server_error
        expect(last_response.body).to eq('rescued from DatabaseError')
      end

      it 'does not rescue a different error' do
        subject.rescue_from RuntimeError do |e|
          error!("rescued from #{e.class.name}", 500)
        end
        subject.get '/uncaught' do
          raise CommunicationError
        end
        expect { get '/uncaught' }.to raise_error(CommunicationError)
      end
    end
  end

  describe '.rescue_from klass, lambda' do
    it 'rescues an error with the lambda' do
      subject.rescue_from ArgumentError, lambda {
        error!('rescued with a lambda', 400)
      }
      subject.get('/rescue_lambda') { raise ArgumentError }

      get '/rescue_lambda'
      expect(last_response).to be_bad_request
      expect(last_response.body).to eq('rescued with a lambda')
    end

    it 'can execute the lambda with an argument' do
      subject.rescue_from ArgumentError, lambda { |e|
        error!(e.message, 400)
      }
      subject.get('/rescue_lambda') { raise ArgumentError, 'lambda takes an argument' }

      get '/rescue_lambda'
      expect(last_response).to be_bad_request
      expect(last_response.body).to eq('lambda takes an argument')
    end
  end

  describe '.rescue_from klass, with: :method_name' do
    it 'rescues an error with the specified method name' do
      subject.helpers do
        def rescue_arg_error
          error!('500 ArgumentError', 500)
        end

        def rescue_no_method_error
          error!('500 NoMethodError', 500)
        end
      end
      subject.rescue_from ArgumentError, with: :rescue_arg_error
      subject.rescue_from NoMethodError, with: :rescue_no_method_error
      subject.get('/rescue_arg_error') { raise ArgumentError }
      subject.get('/rescue_no_method_error') { raise NoMethodError }

      get '/rescue_arg_error'
      expect(last_response).to be_server_error
      expect(last_response.body).to eq('500 ArgumentError')

      get '/rescue_no_method_error'
      expect(last_response).to be_server_error
      expect(last_response.body).to eq('500 NoMethodError')
    end

    it 'aborts if the specified method name does not exist' do
      subject.rescue_from :all, with: :not_exist_method
      subject.get('/rescue_method') { raise StandardError }

      expect { get '/rescue_method' }.to raise_error(NoMethodError, /^undefined method 'not_exist_method'/)
    end

    it 'correctly chooses exception handler if :all handler is specified' do
      subject.helpers do
        def rescue_arg_error
          error!('500 ArgumentError', 500)
        end

        def rescue_all_errors
          error!('500 AnotherError', 500)
        end
      end

      subject.rescue_from ArgumentError, with: :rescue_arg_error
      subject.rescue_from :all, with: :rescue_all_errors
      subject.get('/argument_error') { raise ArgumentError }
      subject.get('/another_error') { raise NoMethodError }

      get '/argument_error'
      expect(last_response).to be_server_error
      expect(last_response.body).to eq('500 ArgumentError')

      get '/another_error'
      expect(last_response).to be_server_error
      expect(last_response.body).to eq('500 AnotherError')
    end
  end

  describe '.rescue_from klass, rescue_subclasses: boolean' do
    before do
      parent_error = Class.new(StandardError)
      stub_const('ApiSpec::APIErrors::ParentError', parent_error)
      stub_const('ApiSpec::APIErrors::ChildError', Class.new(parent_error))
    end

    it 'rescues error as well as subclass errors with rescue_subclasses option set' do
      subject.rescue_from ApiSpec::APIErrors::ParentError, rescue_subclasses: true do |e|
        error!("rescued from #{e.class.name}", 500)
      end
      subject.get '/caught_child' do
        raise ApiSpec::APIErrors::ChildError
      end
      subject.get '/caught_parent' do
        raise ApiSpec::APIErrors::ParentError
      end
      subject.get '/uncaught_parent' do
        raise StandardError
      end

      get '/caught_child'
      expect(last_response).to be_server_error
      get '/caught_parent'
      expect(last_response).to be_server_error
      expect { get '/uncaught_parent' }.to raise_error(StandardError)
    end

    it 'sets rescue_subclasses to true by default' do
      subject.rescue_from ApiSpec::APIErrors::ParentError do |e|
        error!("rescued from #{e.class.name}", 500)
      end
      subject.get '/caught_child' do
        raise ApiSpec::APIErrors::ChildError
      end

      get '/caught_child'
      expect(last_response).to be_server_error
    end

    it 'does not rescue child errors if rescue_subclasses is false' do
      subject.rescue_from ApiSpec::APIErrors::ParentError, rescue_subclasses: false do |e|
        error!("rescued from #{e.class.name}", 500)
      end
      subject.get '/uncaught' do
        raise ApiSpec::APIErrors::ChildError
      end
      expect { get '/uncaught' }.to raise_error(ApiSpec::APIErrors::ChildError)
    end
  end

  describe '.rescue_from :grape_exceptions' do
    before do
      subject.rescue_from :grape_exceptions
    end

    let(:grape_exception) do
      Grape::Exceptions::Base.new(status: 400, message: 'Grape Error')
    end

    it 'rescues grape exceptions' do
      exception = grape_exception
      subject.get('/grape_exception') { raise exception }

      get '/grape_exception'

      expect(last_response.status).to eq(exception.status)
      expect(last_response.body).to eq(exception.message)
    end

    it 'rescues grape exceptions with a user-defined handler' do
      subject.rescue_from grape_exception.class do |_error|
        error!('Redefined Error', 403)
      end

      exception = grape_exception
      subject.get('/grape_exception') { raise exception }

      get '/grape_exception'

      expect(last_response).to be_forbidden
      expect(last_response.body).to eq('Redefined Error')
    end
  end

  describe '.error_format' do
    it 'rescues all errors and return :txt' do
      subject.rescue_from :all
      subject.format :txt
      subject.get '/exception' do
        raise 'rain!'
      end
      get '/exception'
      expect(last_response.body).to eql 'rain!'
    end

    it 'rescues all errors and return :txt with backtrace' do
      subject.rescue_from :all, backtrace: true
      subject.format :txt
      subject.get '/exception' do
        raise 'rain!'
      end
      get '/exception'
      expect(last_response.body.start_with?("rain!\r\n")).to be true
    end

    it 'rescues all errors with a default formatter' do
      subject.default_format :foo
      subject.content_type :foo, 'text/foo'
      subject.rescue_from :all
      subject.get '/exception' do
        raise 'rain!'
      end
      get '/exception.foo'
      expect(last_response.body).to start_with 'rain!'
    end

    it 'defaults the error formatter to format' do
      subject.format :json
      subject.rescue_from :all
      subject.content_type :json, 'application/json'
      subject.content_type :foo, 'text/foo'
      subject.get '/exception' do
        raise 'rain!'
      end
      get '/exception.json'
      expect(last_response.body).to eq('{"error":"rain!"}')
      get '/exception.foo'
      expect(last_response.body).to eq('{"error":"rain!"}')
    end

    context 'class' do
      let(:custom_error_formatter) do
        Class.new do
          def self.call(message, _backtrace, _options, _env, _original_exception)
            "message: #{message} @backtrace"
          end
        end
      end

      it 'returns a custom error format' do
        subject.rescue_from :all, backtrace: true
        subject.error_formatter :txt, custom_error_formatter
        subject.get('/exception') { raise 'rain!' }

        get '/exception'
        expect(last_response.body).to eq('message: rain! @backtrace')
      end

      it 'returns a custom error format (using keyword :with)' do
        subject.rescue_from :all, backtrace: true
        subject.error_formatter :txt, with: custom_error_formatter
        subject.get('/exception') { raise 'rain!' }

        get '/exception'
        expect(last_response.body).to eq('message: rain! @backtrace')
      end

      it 'returns a modified error with a custom error format' do
        subject.rescue_from :all, backtrace: true do |e|
          error!('raining dogs and cats', 418, {}, e.backtrace, e)
        end
        subject.error_formatter :txt, with: custom_error_formatter
        subject.get '/exception' do
          raise 'rain!'
        end
        get '/exception'
        expect(last_response.body).to eq('message: raining dogs and cats @backtrace')
      end
    end

    it 'rescues all errors and return :json' do
      subject.rescue_from :all
      subject.format :json
      subject.get '/exception' do
        raise 'rain!'
      end
      get '/exception'
      expect(last_response.body).to eql '{"error":"rain!"}'
    end

    it 'rescues all errors and return :json with backtrace' do
      subject.rescue_from :all, backtrace: true
      subject.format :json
      subject.get '/exception' do
        raise 'rain!'
      end
      get '/exception'
      json = Grape::Json.load(last_response.body)
      expect(json['error']).to eql 'rain!'
      expect(json['backtrace'].length).to be > 0
    end

    it 'rescues error! and return txt' do
      subject.format :txt
      subject.get '/error' do
        error!('Access Denied', 401)
      end
      get '/error'
      expect(last_response.body).to eql 'Access Denied'
    end

    context 'with json format' do
      shared_examples_for 'a json format api' do |error_message|
        subject { JSON.parse(last_response.body) }

        before  { get '/error' }

        let(:app) do
          Class.new(Grape::API) do
            format :json
            get('/error') { error!(error_message, 401) }
          end
        end

        context "when error! called with #{error_message.class.name}" do
          it { is_expected.to eq('error' => 'failure') }
        end
      end

      it_behaves_like 'a json format api', 'failure'
      it_behaves_like 'a json format api', :failure
      it_behaves_like 'a json format api', { error: :failure }
    end

    context 'when rescue_from enables backtrace without original exception' do
      let(:app) do
        response_type = response_format

        Class.new(Grape::API) do
          format response_type

          rescue_from :all, backtrace: true, original_exception: false do |e|
            error!('raining dogs and cats!', 418, {}, e.backtrace, e)
          end

          get '/exception' do
            raise 'rain!'
          end
        end
      end

      before do
        get '/exception'
      end

      context 'with json response type format' do
        subject { JSON.parse(last_response.body) }

        let(:response_format) { :json }

        it { is_expected.to include('error' => a_kind_of(String), 'backtrace' => a_kind_of(Array)) }
        it { is_expected.not_to include('original_exception') }
      end

      context 'with txt response type format' do
        subject { last_response.body }

        let(:response_format) { :txt }

        it { is_expected.to include('backtrace') }
        it { is_expected.not_to include('original_exception') }
      end

      context 'with xml response type format' do
        subject { Grape::Xml.parse(last_response.body)['error'] }

        let(:response_format) { :xml }

        it { is_expected.to have_key('backtrace') }
        it { is_expected.not_to have_key('original-exception') }
      end
    end

    context 'when rescue_from enables original exception without backtrace' do
      let(:app) do
        response_type = response_format

        Class.new(Grape::API) do
          format response_type

          rescue_from :all, backtrace: false, original_exception: true do |e|
            error!('raining dogs and cats!', 418, {}, e.backtrace, e)
          end

          get '/exception' do
            raise 'rain!'
          end
        end
      end

      before do
        get '/exception'
      end

      context 'with json response type format' do
        subject { JSON.parse(last_response.body) }

        let(:response_format) { :json }

        it { is_expected.to include('error' => a_kind_of(String), 'original_exception' => a_kind_of(String)) }
        it { is_expected.not_to include('backtrace') }
      end

      context 'with txt response type format' do
        subject { last_response.body }

        let(:response_format) { :txt }

        it { is_expected.to include('original exception') }
        it { is_expected.not_to include('backtrace') }
      end

      context 'with xml response type format' do
        subject { Grape::Xml.parse(last_response.body)['error'] }

        let(:response_format) { :xml }

        it { is_expected.to have_key('original-exception') }
        it { is_expected.not_to have_key('backtrace') }
      end
    end

    context 'when rescue_from include backtrace and original exception' do
      let(:app) do
        response_type = response_format

        Class.new(Grape::API) do
          format response_type

          rescue_from :all, backtrace: true, original_exception: true do |e|
            error!('raining dogs and cats!', 418, {}, e.backtrace, e)
          end

          get '/exception' do
            raise 'rain!'
          end
        end
      end

      before do
        get '/exception'
      end

      context 'with json response type format' do
        subject { JSON.parse(last_response.body) }

        let(:response_format) { :json }

        it { is_expected.to include('error' => a_kind_of(String), 'backtrace' => a_kind_of(Array), 'original_exception' => a_kind_of(String)) }
      end

      context 'with txt response type format' do
        subject { last_response.body }

        let(:response_format) { :txt }

        it { is_expected.to include('backtrace', 'original exception') }
      end

      context 'with xml response type format' do
        subject { Grape::Xml.parse(last_response.body)['error'] }

        let(:response_format) { :xml }

        it { is_expected.to have_key('backtrace') & have_key('original-exception') }
      end
    end

    context 'when rescue validation errors include backtrace and original exception' do
      let(:app) do
        response_type = response_format

        Class.new(Grape::API) do
          format response_type

          rescue_from Grape::Exceptions::ValidationErrors, backtrace: true, original_exception: true do |e|
            error!(e, 418, {}, e.backtrace, e)
          end

          params do
            requires :weather
          end
          get '/forecast' do
            'sunny'
          end
        end
      end

      before do
        get '/forecast'
      end

      context 'with json response type format' do
        subject { JSON.parse(last_response.body) }

        let(:response_format) { :json }

        it 'does not include backtrace or original exception' do
          expect(subject).to match([{ 'messages' => ['is missing'], 'params' => ['weather'] }])
        end
      end

      context 'with txt response type format' do
        subject { last_response.body }

        let(:response_format) { :txt }

        it { is_expected.to include('backtrace', 'original exception') }
      end

      context 'with xml response type format' do
        subject { Grape::Xml.parse(last_response.body)['error'] }

        let(:response_format) { :xml }

        it { is_expected.to have_key('backtrace') & have_key('original-exception') }
      end
    end
  end

  describe '.content_type' do
    it 'sets additional content-type' do
      subject.content_type :xls, 'application/vnd.ms-excel'
      subject.get :excel do
        'some binary content'
      end
      get '/excel.xls'
      expect(last_response.content_type).to eq('application/vnd.ms-excel')
    end

    it 'allows to override content-type' do
      subject.get :content do
        content_type 'text/javascript'
        'var x = 1;'
      end
      get '/content'
      expect(last_response.content_type).to eq('text/javascript')
    end

    it 'removes existing content types' do
      subject.content_type :xls, 'application/vnd.ms-excel'
      subject.get :excel do
        'some binary content'
      end
      get '/excel.json'
      expect(last_response.status).to eq(406)
      expect(last_response.body).to eq(Rack::Utils.escape_html("The requested format 'txt' is not supported."))
    end
  end

  describe '.formatter' do
    context 'multiple formatters' do
      before do
        subject.formatter :json, ->(object, _env) { "{\"custom_formatter\":\"#{object[:some]}\"}" }
        subject.formatter :txt, ->(object, _env) { "custom_formatter: #{object[:some]}" }
        subject.get :simple do
          { some: 'hash' }
        end
      end

      it 'sets one formatter' do
        get '/simple.json'
        expect(last_response.body).to eql '{"custom_formatter":"hash"}'
      end

      it 'sets another formatter' do
        get '/simple.txt'
        expect(last_response.body).to eql 'custom_formatter: hash'
      end
    end

    context 'custom formatter' do
      before do
        subject.content_type :json, 'application/json'
        subject.content_type :custom, 'application/custom'
        subject.formatter :custom, ->(object, _env) { "{\"custom_formatter\":\"#{object[:some]}\"}" }
        subject.get :simple do
          { some: 'hash' }
        end
      end

      it 'uses json' do
        get '/simple.json'
        expect(last_response.body).to eql '{"some":"hash"}'
      end

      it 'uses custom formatter' do
        get '/simple.custom', Grape::Http::Headers::HTTP_ACCEPT => 'application/custom'
        expect(last_response.body).to eql '{"custom_formatter":"hash"}'
      end
    end

    context 'custom formatter class' do
      let(:custom_formatter) do
        Module.new do
          def self.call(object, _env)
            "{\"custom_formatter\":\"#{object[:some]}\"}"
          end
        end
      end

      before do
        subject.content_type :json, 'application/json'
        subject.content_type :custom, 'application/custom'
        subject.formatter :custom, custom_formatter
        subject.get :simple do
          { some: 'hash' }
        end
      end

      it 'uses json' do
        get '/simple.json'
        expect(last_response.body).to eql '{"some":"hash"}'
      end

      it 'uses custom formatter' do
        get '/simple.custom', Grape::Http::Headers::HTTP_ACCEPT => 'application/custom'
        expect(last_response.body).to eql '{"custom_formatter":"hash"}'
      end
    end
  end

  describe '.parser' do
    it 'parses data in format requested by content-type' do
      subject.format :json
      subject.post '/data' do
        { x: params[:x] }
      end
      post '/data', '{"x":42}', 'CONTENT_TYPE' => 'application/json'
      expect(last_response).to be_created
      expect(last_response.body).to eq('{"x":42}')
    end

    context 'lambda parser' do
      before do
        subject.content_type :txt, 'text/plain'
        subject.content_type :custom, 'text/custom'
        subject.parser :custom, ->(object, _env) { { object.to_sym => object.to_s.reverse } }
        subject.put :simple do
          params[:simple]
        end
      end

      ['text/custom', 'text/custom; charset=UTF-8'].each do |content_type|
        it "uses parser for #{content_type}" do
          put '/simple', 'simple', 'CONTENT_TYPE' => content_type
          expect(last_response).to be_successful
          expect(last_response.body).to eql 'elpmis'
        end
      end
    end

    context 'custom parser class' do
      let(:custom_parser) do
        Module.new do
          def self.call(object, _env)
            { object.to_sym => object.to_s.reverse }
          end
        end
      end

      before do
        subject.content_type :txt, 'text/plain'
        subject.content_type :custom, 'text/custom'
        subject.parser :custom, custom_parser
        subject.put :simple do
          params[:simple]
        end
      end

      it 'uses custom parser' do
        put '/simple', 'simple', 'CONTENT_TYPE' => 'text/custom'
        expect(last_response).to be_successful
        expect(last_response.body).to eql 'elpmis'
      end
    end

    if Object.const_defined? :MultiXml
      context 'multi_xml' do
        it "doesn't parse yaml" do
          subject.put :yaml do
            params[:tag]
          end
          put '/yaml', '<tag type="symbol">a123</tag>', 'CONTENT_TYPE' => 'application/xml'
          expect(last_response).to be_bad_request
          expect(last_response.body).to eql 'Disallowed type attribute: "symbol"'
        end
      end
    else
      context 'default xml parser' do
        it 'parses symbols' do
          subject.put :yaml do
            params[:tag]
          end
          body = '<tag type="symbol">a123</tag>'
          put '/yaml', body, 'CONTENT_TYPE' => 'application/xml'
          expect(last_response).to be_successful
          expect(last_response.body).to eq(Grape::Xml.parse(body)['tag'].to_s)
        end
      end
    end
    context 'none parser class' do
      before do
        subject.parser :json, nil
        subject.put 'data' do
          "body: #{env[Grape::Env::API_REQUEST_BODY]}"
        end
      end

      it 'does not parse data' do
        put '/data', 'not valid json', 'CONTENT_TYPE' => 'application/json'
        expect(last_response).to be_successful
        expect(last_response.body).to eq('body: not valid json')
      end
    end
  end

  describe '.default_format' do
    before do
      subject.format :json
      subject.default_format :json
    end

    it 'returns data in default format' do
      subject.get '/data' do
        { x: 42 }
      end
      get '/data'
      expect(last_response).to be_successful
      expect(last_response.body).to eq('{"x":42}')
    end

    it 'parses data in default format' do
      subject.post '/data' do
        { x: params[:x] }
      end
      post '/data', '{"x":42}', 'CONTENT_TYPE' => ''
      expect(last_response).to be_created
      expect(last_response.body).to eq('{"x":42}')
    end
  end

  describe '.default_error_status' do
    it 'allows setting default_error_status' do
      subject.rescue_from :all
      subject.default_error_status 200
      subject.get '/exception' do
        raise 'rain!'
      end
      get '/exception'
      expect(last_response).to be_successful
    end

    it 'has a default error status' do
      subject.rescue_from :all
      subject.get '/exception' do
        raise 'rain!'
      end
      get '/exception'
      expect(last_response).to be_server_error
    end

    it 'uses the default error status in error!' do
      subject.rescue_from :all
      subject.default_error_status 400
      subject.get '/exception' do
        error! 'rain!'
      end
      get '/exception'
      expect(last_response).to be_bad_request
    end
  end

  context 'routes' do
    describe 'empty api structure' do
      it 'returns an empty array of routes' do
        expect(subject.routes).to eq([])
      end
    end

    describe 'single method api structure' do
      before do
        subject.get :ping do
          'pong'
        end
      end

      it 'returns one route' do
        expect(subject.routes.size).to eq(1)
        route = subject.routes[0]
        expect(route.version).to be_nil
        expect(route.path).to eq('/ping(.:format)')
        expect(route.request_method).to eq(Rack::GET)
      end
    end

    describe 'api structure with two versions and a namespace' do
      before do
        subject.version 'v1', using: :path
        subject.get 'version' do
          api.version
        end
        # version v2
        subject.version 'v2', using: :path
        subject.prefix 'p'
        subject.namespace 'n1' do
          namespace 'n2' do
            get 'version' do
              api.version
            end
          end
        end
      end

      it 'returns the latest version set' do
        expect(subject.version).to eq('v2')
      end

      it 'returns versions' do
        expect(subject.versions).to eq(%w[v1 v2])
      end

      it 'sets route paths' do
        expect(subject.routes.size).to be >= 2
        expect(subject.routes[0].path).to eq('/:version/version(.:format)')
        expect(subject.routes[1].path).to eq('/p/:version/n1/n2/version(.:format)')
      end

      it 'sets route versions' do
        expect(subject.routes[0].version).to eq('v1')
        expect(subject.routes[1].version).to eq('v2')
      end

      it 'sets a nested namespace' do
        expect(subject.routes[1].namespace).to eq('/n1/n2')
      end

      it 'sets prefix' do
        expect(subject.routes[1].prefix).to eq('p')
      end
    end

    describe 'api structure with additional parameters' do
      before do
        subject.params do
          requires :token, desc: 'a token'
          optional :limit, desc: 'the limit'
        end
        subject.get 'split/:string' do
          params[:string].split(params[:token], (params[:limit] || 0).to_i)
        end
      end

      it 'splits a string' do
        get '/split/a,b,c.json', token: ','
        expect(last_response.body).to eq('["a","b","c"]')
      end

      it 'splits a string with limit' do
        get '/split/a,b,c.json', token: ',', limit: '2'
        expect(last_response.body).to eq('["a","b,c"]')
      end

      it 'sets params' do
        expect(subject.routes.map do |route|
          { params: route.params }
        end).to eq [
          {
            params: {
              'string' => '',
              'token' => { required: true, desc: 'a token' },
              'limit' => { required: false, desc: 'the limit' }
            }
          }
        ]
      end
    end

    describe 'api structure with multiple apis' do
      before do
        subject.params do
          requires :one, desc: 'a token'
          optional :two, desc: 'the limit'
        end
        subject.get 'one' do
        end

        subject.params do
          requires :three, desc: 'a token'
          optional :four, desc: 'the limit'
        end
        subject.get 'two' do
        end
      end

      it 'sets params' do
        expect(subject.routes.map do |route|
          { params: route.params }
        end).to eq [
          {
            params: {
              'one' => { required: true, desc: 'a token' },
              'two' => { required: false, desc: 'the limit' }
            }
          },
          {
            params: {
              'three' => { required: true, desc: 'a token' },
              'four' => { required: false, desc: 'the limit' }
            }
          }
        ]
      end
    end

    describe 'api structure with an api without params' do
      before do
        subject.params do
          requires :one, desc: 'a token'
          optional :two, desc: 'the limit'
        end
        subject.get 'one' do
        end

        subject.get 'two' do
        end
      end

      it 'sets params' do
        expect(subject.routes.map do |route|
          { params: route.params }
        end).to eq [
          {
            params: {
              'one' => { required: true, desc: 'a token' },
              'two' => { required: false, desc: 'the limit' }
            }
          },
          {
            params: {}
          }
        ]
      end
    end

    describe 'api with a custom route setting' do
      before do
        subject.route_setting :custom, key: 'value'
        subject.get 'one'
      end

      it 'exposed' do
        expect(subject.routes.count).to eq 1
        route = subject.routes.first
        expect(route.settings[:custom]).to eq(key: 'value')
      end
    end

    describe 'status' do
      it 'can be set to arbitrary Integer value' do
        subject.get '/foo' do
          status 210
        end
        get '/foo'
        expect(last_response.status).to eq 210
      end

      it 'can be set with a status code symbol' do
        subject.get '/foo' do
          status :see_other
        end
        get '/foo'
        expect(last_response.status).to eq 303
      end
    end
  end

  context 'desc' do
    it 'empty array of routes' do
      expect(subject.routes).to eq([])
    end

    it 'empty array of routes' do
      subject.desc 'grape api'
      expect(subject.routes).to eq([])
    end

    it 'describes a method' do
      subject.desc 'first method'
      subject.get :first
      expect(subject.routes.length).to eq(1)
      route = subject.routes.first
      expect(route.description).to eq('first method')
      expect(route.params).to eq({})
      expect(route.options).to be_a(Hash)
    end

    it 'has params which does not include format and version as named captures' do
      subject.version :v1, using: :path
      subject.get :first
      param_keys = subject.routes.first.params.keys
      expect(param_keys).not_to include('format')
      expect(param_keys).not_to include('version')
    end

    it 'describes methods separately' do
      subject.desc 'first method'
      subject.get :first
      subject.desc 'second method'
      subject.get :second
      expect(subject.routes.count).to eq(2)
      expect(subject.routes.map do |route|
        { description: route.description, params: route.params }
      end).to eq [
        { description: 'first method', params: {} },
        { description: 'second method', params: {} }
      ]
    end

    it 'resets desc' do
      subject.desc 'first method'
      subject.get :first
      subject.get :second
      expect(subject.routes.map do |route|
        { description: route.description, params: route.params }
      end).to eq [
        { description: 'first method', params: {} },
        { description: nil, params: {} }
      ]
    end

    it 'namespaces and describe arbitrary parameters' do
      subject.namespace 'ns' do
        desc 'ns second', foo: 'bar'
        get 'second'
      end
      expect(subject.routes.map do |route|
        { description: route.description, foo: route.options[:foo], params: route.params }
      end).to eq [
        { description: 'ns second', foo: 'bar', params: {} }
      ]
    end

    it 'includes detail' do
      subject.desc 'method', detail: 'method details'
      subject.get 'method'
      expect(subject.routes.map do |route|
        { description: route.description, detail: route.detail, params: route.params }
      end).to eq [
        { description: 'method', detail: 'method details', params: {} }
      ]
    end

    it 'describes a method with parameters' do
      subject.desc 'Reverses a string.', params: { 's' => { desc: 'string to reverse', type: 'string' } }
      subject.get 'reverse' do
        params[:s].reverse
      end
      expect(subject.routes.map do |route|
        { description: route.description, params: route.params }
      end).to eq [
        { description: 'Reverses a string.', params: { 's' => { desc: 'string to reverse', type: 'string' } } }
      ]
    end

    it 'does not inherit param descriptions in consequent namespaces' do
      subject.desc 'global description'
      subject.params do
        requires :param1
        optional :param2
      end
      subject.namespace 'ns1' do
        get {}
      end
      subject.params do
        optional :param2
      end
      subject.namespace 'ns2' do
        get {}
      end
      routes_doc = subject.routes.map do |route|
        { description: route.description, params: route.params }
      end
      expect(routes_doc).to eq [
        { description: 'global description',
          params: {
            'param1' => { required: true },
            'param2' => { required: false }
          } },
        { description: 'global description',
          params: {
            'param2' => { required: false }
          } }
      ]
    end

    it 'merges the parameters of the namespace with the parameters of the method' do
      subject.desc 'namespace'
      subject.params do
        requires :ns_param, desc: 'namespace parameter'
      end
      subject.namespace 'ns' do
        desc 'method'
        params do
          optional :method_param, desc: 'method parameter'
        end
        get 'method'
      end

      routes_doc = subject.routes.map do |route|
        { description: route.description, params: route.params }
      end
      expect(routes_doc).to eq [
        { description: 'method',
          params: {
            'ns_param' => { required: true, desc: 'namespace parameter' },
            'method_param' => { required: false, desc: 'method parameter' }
          } }
      ]
    end

    it 'merges the parameters of nested namespaces' do
      subject.desc 'ns1'
      subject.params do
        optional :ns_param, desc: 'ns param 1'
        requires :ns1_param, desc: 'ns1 param'
      end
      subject.namespace 'ns1' do
        desc 'ns2'
        params do
          requires :ns_param, desc: 'ns param 2'
          requires :ns2_param, desc: 'ns2 param'
        end
        namespace 'ns2' do
          desc 'method'
          params do
            optional :method_param, desc: 'method param'
          end
          get 'method'
        end
      end
      expect(subject.routes.map do |route|
        { description: route.description, params: route.params }
      end).to eq [
        { description: 'method',
          params: {
            'ns_param' => { required: true, desc: 'ns param 2' },
            'ns1_param' => { required: true, desc: 'ns1 param' },
            'ns2_param' => { required: true, desc: 'ns2 param' },
            'method_param' => { required: false, desc: 'method param' }
          } }
      ]
    end

    it 'groups nested params and prevents overwriting of params with same name in different groups' do
      subject.desc 'method'
      subject.params do
        group :group1, type: Array do
          optional :param1, desc: 'group1 param1 desc'
          requires :param2, desc: 'group1 param2 desc'
        end
        group :group2, type: Array do
          optional :param1, desc: 'group2 param1 desc'
          requires :param2, desc: 'group2 param2 desc'
        end
      end
      subject.get 'method'

      expect(subject.routes.map(&:params)).to eq [{
        'group1' => { required: true, type: 'Array' },
        'group1[param1]' => { required: false, desc: 'group1 param1 desc' },
        'group1[param2]' => { required: true, desc: 'group1 param2 desc' },
        'group2' => { required: true, type: 'Array' },
        'group2[param1]' => { required: false, desc: 'group2 param1 desc' },
        'group2[param2]' => { required: true, desc: 'group2 param2 desc' }
      }]
    end

    it 'uses full name of parameters in nested groups' do
      subject.desc 'nesting'
      subject.params do
        requires :root_param, desc: 'root param'
        group :nested, type: Array do
          requires :nested_param, desc: 'nested param'
        end
      end
      subject.get 'method'
      expect(subject.routes.map do |route|
        { description: route.description, params: route.params }
      end).to eq [
        { description: 'nesting',
          params: {
            'root_param' => { required: true, desc: 'root param' },
            'nested' => { required: true, type: 'Array' },
            'nested[nested_param]' => { required: true, desc: 'nested param' }
          } }
      ]
    end

    it 'allows to set the type attribute on :group element' do
      subject.params do
        group :foo, type: Array do
          optional :bar
        end
      end
      subject.get 'method'
      expect(subject.routes.map do |route|
        { description: route.description, params: route.params }
      end).to eq [
        { description: nil, params: { 'foo' => { required: true, type: 'Array' }, 'foo[bar]' => { required: false } } }
      ]
    end

    it 'parses parameters when no description is given' do
      subject.params do
        requires :one_param, desc: 'one param'
      end
      subject.get 'method'
      expect(subject.routes.map do |route|
        { description: route.description, params: route.params }
      end).to eq [
        { description: nil, params: { 'one_param' => { required: true, desc: 'one param' } } }
      ]
    end

    it 'does not symbolize params' do
      subject.desc 'Reverses a string.', params: { 's' => { desc: 'string to reverse', type: 'string' } }
      subject.get 'reverse/:s' do
        params[:s].reverse
      end
      expect(subject.routes.map do |route|
        { description: route.description, params: route.params }
      end).to eq [
        { description: 'Reverses a string.', params: { 's' => { desc: 'string to reverse', type: 'string' } } }
      ]
    end
  end

  describe '.mount' do
    let(:mounted_app) { ->(_env) { [200, {}, ['MOUNTED']] } }

    context 'with a bare rack app' do
      before do
        subject.mount mounted_app => '/mounty'
      end

      it 'makes a bare Rack app available at the endpoint' do
        get '/mounty'
        expect(last_response.body).to eq('MOUNTED')
      end

      it 'anchors the routes, passing all subroutes to it' do
        get '/mounty/awesome'
        expect(last_response.body).to eq('MOUNTED')
      end

      it 'is able to cascade' do
        subject.mount lambda { |env|
          headers = {}
          headers[Grape::Http::Headers::X_CASCADE] == 'pass' if env[Rack::PATH_INFO].exclude?('boo')
          [200, headers, ['Farfegnugen']]
        } => '/'

        get '/boo'
        expect(last_response.body).to eq('Farfegnugen')
        get '/mounty'
        expect(last_response.body).to eq('MOUNTED')
      end
    end

    context 'without a hash' do
      it 'calls through setting the route to "/"' do
        subject.mount mounted_app
        get '/'
        expect(last_response.body).to eq('MOUNTED')
      end
    end

    context 'mounting an API' do
      it 'applies the settings of the mounting api' do
        subject.version 'v1', using: :path

        subject.namespace :cool do
          app = Class.new(Grape::API) # rubocop:disable RSpec/DescribedClass
          app.get('/awesome') do
            'yo'
          end

          mount app
        end

        get '/v1/cool/awesome'
        expect(last_response.body).to eq('yo')
      end

      it 'applies the settings to nested mounted apis' do
        subject.version 'v1', using: :path

        subject.namespace :cool do
          inner_app = Class.new(Grape::API) # rubocop:disable RSpec/DescribedClass
          inner_app.get('/awesome') do
            'yo'
          end

          app = Class.new(Grape::API) # rubocop:disable RSpec/DescribedClass
          app.mount inner_app
          mount app
        end

        get '/v1/cool/awesome'
        expect(last_response.body).to eq('yo')
      end

      context 'when some rescues are defined by mounted' do
        it 'inherits parent rescues' do
          subject.rescue_from :all do |e|
            error!("rescued from #{e.message}", 202)
          end

          app = Class.new(described_class)

          subject.namespace :mounted do
            app.rescue_from ArgumentError
            app.get('/fail') { raise 'doh!' }
            mount app
          end

          get '/mounted/fail'
          expect(last_response).to be_accepted
          expect(last_response.body).to eq('rescued from doh!')
        end

        it 'prefers rescues defined by mounted if they rescue similar error class' do
          subject.rescue_from StandardError do
            error!('outer rescue')
          end

          app = Class.new(described_class)

          subject.namespace :mounted do
            rescue_from StandardError do
              error!('inner rescue')
            end
            app.get('/fail') { raise 'doh!' }
            mount app
          end

          get '/mounted/fail'
          expect(last_response.body).to eq('inner rescue')
        end

        it 'prefers rescues defined by mounted even if outer is more specific' do
          subject.rescue_from ArgumentError do
            error!('outer rescue')
          end

          app = Class.new(described_class)

          subject.namespace :mounted do
            rescue_from StandardError do
              error!('inner rescue')
            end
            app.get('/fail') { raise ArgumentError.new }
            mount app
          end

          get '/mounted/fail'
          expect(last_response.body).to eq('inner rescue')
        end

        it 'prefers more specific rescues defined by mounted' do
          subject.rescue_from StandardError do
            error!('outer rescue')
          end

          app = Class.new(described_class)

          subject.namespace :mounted do
            rescue_from ArgumentError do
              error!('inner rescue')
            end
            app.get('/fail') { raise ArgumentError.new }
            mount app
          end

          get '/mounted/fail'
          expect(last_response.body).to eq('inner rescue')
        end
      end

      it 'collects the routes of the mounted api' do
        subject.namespace :cool do
          app = Class.new(Grape::API) # rubocop:disable RSpec/DescribedClass
          app.get('/awesome') {}
          app.post('/sauce') {}
          mount app
        end
        expect(subject.routes.size).to eq(2)
        expect(subject.routes.first.path).to match(%r{/cool/awesome})
        expect(subject.routes.last.path).to match(%r{/cool/sauce})
      end

      it 'mounts on a path' do
        subject.namespace :cool do
          app = Class.new(Grape::API) # rubocop:disable RSpec/DescribedClass
          app.get '/awesome' do
            'sauce'
          end
          mount app => '/mounted'
        end
        get '/mounted/cool/awesome'
        expect(last_response).to be_successful
        expect(last_response.body).to eq('sauce')
      end

      it 'mounts on a nested path' do
        app1 = Class.new(described_class)
        app2 = Class.new(described_class)
        app2.get '/nice' do
          'play'
        end
        # NOTE: that the reverse won't work, mount from outside-in
        app3 = subject
        app3.mount app1 => '/app1'
        app1.mount app2 => '/app2'
        get '/app1/app2/nice'
        expect(last_response).to be_successful
        expect(last_response.body).to eq('play')
        options '/app1/app2/nice'
        expect(last_response).to be_no_content
      end

      it 'responds to options' do
        app = Class.new(described_class)
        app.get '/colour' do
          'red'
        end
        app.namespace :pears do
          get '/colour' do
            'green'
          end
        end
        subject.namespace :apples do
          mount app
        end

        get '/apples/colour'
        expect(last_response).to be_successful
        expect(last_response.body).to eq('red')
        options '/apples/colour'
        expect(last_response).to be_no_content
        get '/apples/pears/colour'
        expect(last_response).to be_successful
        expect(last_response.body).to eq('green')
        options '/apples/pears/colour'
        expect(last_response).to be_no_content
      end

      it 'responds to options with path versioning' do
        subject.version 'v1', using: :path
        subject.namespace :apples do
          app = Class.new(Grape::API) # rubocop:disable RSpec/DescribedClass
          app.get('/colour') do
            'red'
          end
          mount app
        end

        get '/v1/apples/colour'
        expect(last_response).to be_successful
        expect(last_response.body).to eq('red')
        options '/v1/apples/colour'
        expect(last_response).to be_no_content
      end

      it 'mounts a versioned API with nested resources' do
        api = Class.new(described_class) do
          version 'v1'
          resources :users do
            get :hello do
              'hello users'
            end
          end
        end
        subject.mount api

        get '/v1/users/hello'
        expect(last_response.body).to eq('hello users')
      end

      it 'mounts a prefixed API with nested resources' do
        api = Class.new(described_class) do
          prefix 'api'
          resources :users do
            get :hello do
              'hello users'
            end
          end
        end
        subject.mount api

        get '/api/users/hello'
        expect(last_response.body).to eq('hello users')
      end

      it 'applies format to a mounted API with nested resources' do
        api = Class.new(described_class) do
          format :json
          resources :users do
            get do
              { users: true }
            end
          end
        end
        subject.mount api

        get '/users'
        expect(last_response.body).to eq({ users: true }.to_json)
      end

      it 'applies auth to a mounted API with nested resources' do
        api = Class.new(described_class) do
          format :json
          http_basic do |username, password|
            username == 'username' && password == 'password'
          end
          resources :users do
            get do
              { users: true }
            end
          end
        end
        subject.mount api

        get '/users'
        expect(last_response).to be_unauthorized

        get '/users', {}, 'HTTP_AUTHORIZATION' => encode_basic_auth('username', 'password')
        expect(last_response.body).to eq({ users: true }.to_json)
      end

      it 'mounts multiple versioned APIs with nested resources' do
        api1 = Class.new(described_class) do
          version 'one', using: :header, vendor: 'test'
          resources :users do
            get :hello do
              'one'
            end
          end
        end

        api2 = Class.new(described_class) do
          version 'two', using: :header, vendor: 'test'
          resources :users do
            get :hello do
              'two'
            end
          end
        end

        subject.mount api1
        subject.mount api2

        versioned_get '/users/hello', 'one', using: :header, vendor: 'test'
        expect(last_response.body).to eq('one')
        versioned_get '/users/hello', 'two', using: :header, vendor: 'test'
        expect(last_response.body).to eq('two')
      end

      it 'recognizes potential versions with mounted path' do
        a = Class.new(described_class) do
          version :v1, using: :path

          get '/hello' do
            'hello'
          end
        end

        b = Class.new(described_class) do
          version :v1, using: :path

          get '/world' do
            'world'
          end
        end

        subject.mount a => '/one'
        subject.mount b => '/two'

        get '/one/v1/hello'
        expect(last_response).to be_successful

        get '/two/v1/world'
        expect(last_response).to be_successful
      end

      context 'when mounting class extends a subclass of Grape::API' do
        it 'mounts APIs with the same superclass' do
          base_api = Class.new(described_class)
          a = Class.new(base_api)
          b = Class.new(base_api)

          expect { a.mount b }.not_to raise_error
        end
      end

      context 'when including a module' do
        let(:included_module) do
          Module.new do
            def self.included(base)
              base.extend(ClassMethods)
            end
          end
        end

        before do
          stub_const(
            'ClassMethods',
            Module.new do
              def my_method
                @test = true
              end
            end
          )
        end

        it 'correctlies include module in nested mount' do
          module_to_include = included_module
          v1 = Class.new(described_class) do
            version :v1, using: :path
            include module_to_include
            my_method
          end
          v2 = Class.new(described_class) do
            version :v2, using: :path
          end
          segment_base = Class.new(described_class) do
            mount v1
            mount v2
          end

          Class.new(described_class) do
            mount segment_base
          end

          expect(v1.my_method).to be_truthy
        end
      end
    end
  end

  describe '.endpoints' do
    it 'adds one for each route created' do
      subject.get '/'
      subject.post '/'
      expect(subject.endpoints.size).to eq(2)
    end
  end

  describe '.compile' do
    it 'sets the instance' do
      expect(subject.instance).to be_nil
      subject.compile
      expect(subject.instance).to be_a(subject.base_instance)
    end
  end

  describe '.change!' do
    it 'invalidates any compiled instance' do
      subject.compile
      subject.change!
      expect(subject.instance).to be_nil
    end
  end

  describe '.endpoint' do
    before do
      subject.format :json
      subject.get '/endpoint/options' do
        {
          path: options[:path],
          source_location: source.source_location
        }
      end
    end

    it 'path' do
      get '/endpoint/options'
      options = Grape::Json.load(last_response.body)
      expect(options['path']).to eq(['/endpoint/options'])
      expect(options['source_location'][0]).to include 'api_spec.rb'
      expect(options['source_location'][1].to_i).to be > 0
    end
  end

  describe '.route' do
    context 'plain' do
      before do
        subject.get '/' do
          route.path
        end
        subject.get '/path' do
          route.path
        end
      end

      it 'provides access to route info' do
        get '/'
        expect(last_response.body).to eq('/(.:format)')
        get '/path'
        expect(last_response.body).to eq('/path(.:format)')
      end
    end

    context 'with desc' do
      before do
        subject.desc 'returns description'
        subject.get '/description' do
          route.description
        end
        subject.desc 'returns parameters', params: { 'x' => 'y' }
        subject.get '/params/:id' do
          route.params[params[:id]]
        end
      end

      it 'returns route description' do
        get '/description'
        expect(last_response.body).to eq('returns description')
      end

      it 'returns route parameters' do
        get '/params/x'
        expect(last_response.body).to eq('y')
      end
    end
  end

  describe '.format' do
    context ':txt' do
      before do
        subject.format :txt
        subject.content_type :json, 'application/json'
        subject.get '/meaning_of_life' do
          { meaning_of_life: 42 }
        end
      end

      it 'forces txt without an extension' do
        get '/meaning_of_life'
        expect(last_response.body).to eq({ meaning_of_life: 42 }.to_s)
      end

      it 'does not force txt with an extension' do
        get '/meaning_of_life.json'
        expect(last_response.body).to eq({ meaning_of_life: 42 }.to_json)
      end

      it 'forces txt from a non-accepting header' do
        get '/meaning_of_life', {}, Grape::Http::Headers::HTTP_ACCEPT => 'application/json'
        expect(last_response.body).to eq({ meaning_of_life: 42 }.to_s)
      end
    end

    context ':txt only' do
      before do
        subject.format :txt
        subject.get '/meaning_of_life' do
          { meaning_of_life: 42 }
        end
      end

      it 'forces txt without an extension' do
        get '/meaning_of_life'
        expect(last_response.body).to eq({ meaning_of_life: 42 }.to_s)
      end

      it 'accepts specified extension' do
        get '/meaning_of_life.txt'
        expect(last_response.body).to eq({ meaning_of_life: 42 }.to_s)
      end

      it 'does not accept extensions other than specified' do
        get '/meaning_of_life.json'
        expect(last_response).to be_not_found
      end

      it 'forces txt from a non-accepting header' do
        get '/meaning_of_life', {}, Grape::Http::Headers::HTTP_ACCEPT => 'application/json'
        expect(last_response.body).to eq({ meaning_of_life: 42 }.to_s)
      end
    end

    context ':json' do
      before do
        subject.format :json
        subject.content_type :txt, 'text/plain'
        subject.get '/meaning_of_life' do
          { meaning_of_life: 42 }
        end
      end

      it 'forces json without an extension' do
        get '/meaning_of_life'
        expect(last_response.body).to eq({ meaning_of_life: 42 }.to_json)
      end

      it 'does not force json with an extension' do
        get '/meaning_of_life.txt'
        expect(last_response.body).to eq({ meaning_of_life: 42 }.to_s)
      end

      it 'forces json from a non-accepting header' do
        get '/meaning_of_life', {}, Grape::Http::Headers::HTTP_ACCEPT => 'text/html'
        expect(last_response.body).to eq({ meaning_of_life: 42 }.to_json)
      end

      it 'can be overwritten with an explicit api_format' do
        subject.get '/meaning_of_life_with_content_type' do
          api_format :txt
          { meaning_of_life: 42 }.to_s
        end
        get '/meaning_of_life_with_content_type'
        expect(last_response.body).to eq({ meaning_of_life: 42 }.to_s)
      end

      it 'raised :error from middleware' do
        middleware = Class.new(Grape::Middleware::Base) do
          def before
            throw :error, message: 'Unauthorized', status: 500
          end
        end
        subject.use middleware
        subject.get do
        end
        get '/'
        expect(last_response).to be_server_error
        expect(last_response.body).to eq({ error: 'Unauthorized' }.to_json)
      end
    end

    context ':serializable_hash' do
      before do
        stub_const(
          'SerializableHashExample',
          Class.new do
            def serializable_hash
              { abc: 'def' }
            end
          end
        )

        subject.format :serializable_hash
      end

      it 'instance' do
        subject.get '/example' do
          SerializableHashExample.new
        end
        get '/example'
        expect(last_response.body).to eq('{"abc":"def"}')
      end

      it 'root' do
        subject.get '/example' do
          { 'root' => SerializableHashExample.new }
        end
        get '/example'
        expect(last_response.body).to eq('{"root":{"abc":"def"}}')
      end

      it 'array' do
        subject.get '/examples' do
          [SerializableHashExample.new, SerializableHashExample.new]
        end
        get '/examples'
        expect(last_response.body).to eq('[{"abc":"def"},{"abc":"def"}]')
      end
    end

    context ':xml' do
      before do
        subject.format :xml
      end

      it 'string' do
        subject.get '/example' do
          'example'
        end
        get '/example'
        expect(last_response).to be_server_error
        expect(last_response.body).to eq <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <error>
            <message>cannot convert String to xml</message>
          </error>
        XML
      end

      it 'hash' do
        subject.get '/example' do
          {
            example1: 'example1',
            example2: 'example2'
          }
        end
        get '/example'
        expect(last_response).to be_successful
        expect(last_response.body).to eq <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <hash>
            <example1>example1</example1>
            <example2>example2</example2>
          </hash>
        XML
      end

      it 'array' do
        subject.get '/example' do
          %w[example1 example2]
        end
        get '/example'
        expect(last_response).to be_successful
        expect(last_response.body).to eq <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <strings type="array">
            <string>example1</string>
            <string>example2</string>
          </strings>
        XML
      end

      it 'raised :error from middleware' do
        middleware = Class.new(Grape::Middleware::Base) do
          def before
            throw :error, message: 'Unauthorized', status: 500
          end
        end
        subject.use middleware
        subject.get do
        end
        get '/'
        expect(last_response.status).to eq(500)
        expect(last_response.body).to eq <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <error>
            <message>Unauthorized</message>
          </error>
        XML
      end
    end
  end

  describe '.configure' do
    context 'when given a block' do
      it 'returns self' do
        expect(subject.configure {}).to be subject
      end

      it 'calls the block passing the config' do
        call = [false, nil]
        subject.configure do |config|
          call = [true, config]
        end

        expect(call[0]).to be true
        expect(call[1]).not_to be_nil
      end
    end

    context 'when not given a block' do
      it 'returns a configuration object' do
        expect(subject.configure).to respond_to(:[], :[]=)
      end
    end

    it 'allows configuring the api' do
      subject.configure do |config|
        config[:hello] = 'hello'
        config[:bread] = 'bread'
      end

      subject.get '/hello-bread' do
        "#{configuration[:hello]} #{configuration[:bread]}"
      end

      get '/hello-bread'
      expect(last_response.body).to eq 'hello bread'
    end
  end

  context 'catch-all' do
    before do
      api1 = Class.new(described_class)
      api1.version 'v1', using: :path
      api1.get 'hello' do
        'v1'
      end
      api2 = Class.new(described_class)
      api2.version 'v2', using: :path
      api2.get 'hello' do
        'v2'
      end
      subject.mount api1
      subject.mount api2
    end

    [true, false].each do |anchor|
      it "anchor=#{anchor}" do
        subject.route :any, '*path', anchor: anchor do
          error!("Unrecognized request path: #{params[:path]} - #{env[Rack::PATH_INFO]}#{env[Rack::SCRIPT_NAME]}", 404)
        end
        get '/v1/hello'
        expect(last_response).to be_successful
        expect(last_response.body).to eq('v1')
        get '/v2/hello'
        expect(last_response).to be_successful
        expect(last_response.body).to eq('v2')
        options '/v2/hello'
        expect(last_response).to be_no_content
        expect(last_response.body).to be_blank
        head '/v2/hello'
        expect(last_response).to be_successful
        expect(last_response.body).to be_blank
        get '/foobar'
        expect(last_response).to be_not_found
        expect(last_response.body).to eq('Unrecognized request path: foobar - /foobar')
      end
    end
  end

  context 'cascading' do
    context 'via version' do
      it 'cascades' do
        subject.version 'v1', using: :path, cascade: true
        get '/v1/hello'
        expect(last_response).to be_not_found
        expect(last_response.headers[Grape::Http::Headers::X_CASCADE]).to eq('pass')
      end

      it 'does not cascade' do
        subject.version 'v2', using: :path, cascade: false
        get '/v2/hello'
        expect(last_response).to be_not_found
        expect(last_response.headers.keys).not_to include Grape::Http::Headers::X_CASCADE
      end
    end

    context 'via endpoint' do
      it 'cascades' do
        subject.cascade true
        get '/hello'
        expect(last_response).to be_not_found
        expect(last_response.headers[Grape::Http::Headers::X_CASCADE]).to eq('pass')
      end

      it 'does not cascade' do
        subject.cascade false
        get '/hello'
        expect(last_response).to be_not_found
        expect(last_response.headers.keys).not_to include Grape::Http::Headers::X_CASCADE
      end
    end
  end

  context 'with json default_error_formatter' do
    it 'returns json error' do
      subject.content_type :json, 'application/json'
      subject.default_error_formatter :json
      subject.get '/something' do
        'foo'
      end
      get '/something'
      expect(last_response.status).to eq(406)
      expect(last_response.body).to eq(Rack::Utils.escape_html({ error: "The requested format 'txt' is not supported." }.to_json))
    end
  end

  context 'with unsafe HTML format specified' do
    it 'escapes the HTML' do
      subject.content_type :json, 'application/json'
      subject.get '/something' do
        'foo'
      end
      get '/something?format=<script>blah</script>'
      expect(last_response.status).to eq(406)
      expect(last_response.body).to eq(Rack::Utils.escape_html("The requested format '<script>blah</script>' is not supported."))
    end
  end

  context 'with non-UTF-8 characters in specified format' do
    it 'converts the characters' do
      subject.format :json
      subject.content_type :json, 'application/json'
      subject.get '/something' do
        'foo'
      end
      get '/something?format=%0A%0B%BF'
      expect(last_response.status).to eq(406)
      message = "The requested format '\n\u000b\357\277\275' is not supported."
      expect(last_response.body).to eq({ error: message }.to_json)
    end
  end

  context 'body' do
    context 'false' do
      before do
        subject.get '/blank' do
          body false
        end
      end

      it 'returns blank body' do
        get '/blank'
        expect(last_response).to be_no_content
        expect(last_response.body).to be_blank
      end
    end

    context 'plain text' do
      before do
        subject.get '/text' do
          content_type 'text/plain'
          body 'Hello World'
          'ignored'
        end
      end

      it 'returns blank body' do
        get '/text'
        expect(last_response).to be_successful
        expect(last_response.body).to eq 'Hello World'
      end
    end
  end

  describe 'normal class methods' do
    subject(:grape_api) { Class.new(described_class) }

    before do
      stub_const('MyAPI', grape_api)
    end

    it 'can find the appropiate name' do
      expect(grape_api.name).to eq 'MyAPI'
    end

    it 'is equal to itself' do
      expect(grape_api.itself).to eq grape_api
      expect(grape_api).to eq MyAPI
      expect(grape_api.eql?(MyAPI))
    end
  end

  describe '.inherited' do
    context 'overriding within class' do
      let(:root_api) do
        Class.new(described_class) do
          @bar = 'Hello, world'

          def self.inherited(child_api)
            super
            child_api.instance_variable_set(:@foo, @bar.dup)
          end
        end
      end

      let(:child_api) { Class.new(root_api) }

      it 'allows overriding the hook' do
        expect(child_api.instance_variable_get(:@foo)).to eq('Hello, world')
      end
    end

    it 'does not override methods inherited from Class' do
      Class.define_method(:test_method) {}
      subclass = Class.new(described_class)
      expect(subclass).not_to receive(:add_setup)
      subclass.test_method
    ensure
      Class.remove_method(:test_method)
    end

    context 'overriding via composition' do
      let(:inherited) do
        Module.new do
          def inherited(api)
            super
            api.instance_variable_set(:@foo, @bar.dup)
          end
        end
      end

      let(:root_api) do
        context = self

        Class.new(described_class) do
          @bar = 'Hello, world'
          extend context.inherited
        end
      end

      let(:child_api) { Class.new(root_api) }

      it 'allows overriding the hook' do
        expect(child_api.instance_variable_get(:@foo)).to eq('Hello, world')
      end
    end
  end

  describe 'const_missing' do
    subject(:grape_api) { Class.new(described_class) }

    let(:mounted) do
      Class.new(described_class) do
        get '/missing' do
          SomeRandomConstant
        end
      end
    end

    before { subject.mount mounted => '/const' }

    it 'raises an error' do
      expect { get '/const/missing' }.to raise_error(NameError).with_message(/SomeRandomConstant/)
    end
  end

  describe 'custom route helpers on nested APIs' do
    subject(:grape_api) do
      Class.new(described_class) do
        version 'v1', using: :path
      end
    end

    let(:shared_api_module) do
      Module.new do
        # rubocop:disable Style/ExplicitBlockArgument because this causes
        #   the underlying issue in this form
        def uniqe_id_route
          params do
            use :unique_id
          end
          route_param(:id) do
            yield
          end
        end
        # rubocop:enable Style/ExplicitBlockArgument
      end
    end
    let(:shared_api_definitions) do
      Module.new do
        extend ActiveSupport::Concern

        included do
          helpers do
            params :unique_id do
              requires :id, type: String,
                            allow_blank: false,
                            regexp: /\d+-\d+/
            end
          end
        end
      end
    end
    let(:orders_root) do
      shared = shared_api_definitions
      find = orders_find_endpoint
      Class.new(described_class) do
        include shared

        namespace(:orders) do
          mount find
        end
      end
    end
    let(:orders_find_endpoint) do
      shared = shared_api_definitions
      Class.new(described_class) do
        include shared

        uniqe_id_route do
          desc 'Fetch a single order' do
            detail 'While specifying the order id on the route'
          end
          get { params[:id] }
        end
      end
    end

    before do
      Grape::API::Instance.extend(shared_api_module)
      subject.mount orders_root
    end

    it 'returns an error when the id is bad' do
      get '/v1/orders/abc'
      expect(last_response.body).to eq('id is invalid')
    end

    it 'returns the given id when it is valid' do
      get '/v1/orders/1-2'
      expect(last_response.body).to eq('1-2')
    end
  end

  context 'instance variables' do
    context 'when setting instance variables in a before validation' do
      it 'is accessible inside the endpoint' do
        expected_instance_variable_value = 'wadus'

        subject.before do
          @my_var = expected_instance_variable_value
        end

        subject.get('/') do
          { my_var: @my_var }.to_json
        end

        get '/'
        expect(last_response.body).to eq({ my_var: expected_instance_variable_value }.to_json)
      end
    end

    context 'when setting instance variables inside the endpoint code' do
      it 'is accessible inside the rescue_from handler' do
        expected_instance_variable_value = 'wadus'

        subject.rescue_from(:all) do
          body = { my_var: @my_var }
          error!(body, 400)
        end

        subject.get('/') do
          @my_var = expected_instance_variable_value
          raise
        end

        get '/'
        expect(last_response).to be_bad_request
        expect(last_response.body).to eq({ my_var: expected_instance_variable_value }.to_json)
      end

      it 'is NOT available in other endpoints of the same api' do
        expected_instance_variable_value = 'wadus'

        subject.get('/first') do
          @my_var = expected_instance_variable_value
          { my_var: @my_var }.to_json
        end

        subject.get('/second') do
          { my_var: @my_var }.to_json
        end

        get '/first'
        expect(last_response.body).to eq({ my_var: expected_instance_variable_value }.to_json)
        get '/second'
        expect(last_response.body).to eq({ my_var: nil }.to_json)
      end
    end

    context 'when set type to a route_param' do
      context 'and the param does not match' do
        it 'returns a 404 response' do
          subject.namespace :books do
            route_param :id, type: Integer do
              get do
                params[:id]
              end
            end
          end

          get '/books/other'
          expect(last_response).to be_not_found
        end
      end
    end
  end

  context 'rack_response deprecated' do
    let(:app) do
      Class.new(described_class) do
        rescue_from :all do
          rack_response('deprecated', 500, 'Content-Type' => 'text/plain')
        end

        get 'test' do
          raise ArgumentError
        end
      end
    end

    it 'raises a deprecation' do
      expect(Grape.deprecator).to receive(:warn).with('The rack_response method has been deprecated, use error! instead.')
      get 'test'
      expect(last_response.body).to eq('deprecated')
    end
  end

  context 'rescue_from context' do
    subject { last_response }

    let(:api) do
      Class.new(described_class) do
        rescue_from :all do
          error!(context.env, 400)
        end
        get { raise ArgumentError, 'Oops!' }
      end
    end

    let(:app) { api }

    before { get '/' }

    it { is_expected.to be_bad_request }
  end

  context "when rescue_from's block raises an error" do
    subject { last_response.body }

    let(:api) do
      Class.new(described_class) do
        rescue_from :all do
          raise ArgumentError, 'This one!'
        end
        get { raise ArgumentError, 'Oops!' }
      end
    end

    let(:app) { api }

    before { get '/' }

    it { is_expected.to eq('This one!') }
  end
end
