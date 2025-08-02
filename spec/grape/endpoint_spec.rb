# frozen_string_literal: true

describe Grape::Endpoint do
  subject { Class.new(Grape::API) }

  def app
    subject
  end

  describe '.before_each' do
    after { described_class.before_each.clear }

    it 'is settable via block' do
      block = ->(_endpoint) { 'noop' }
      described_class.before_each(&block)
      expect(described_class.before_each.first).to eq(block)
    end

    it 'is settable via reference' do
      block = ->(_endpoint) { 'noop' }
      described_class.before_each block
      expect(described_class.before_each.first).to eq(block)
    end

    it 'is able to override a helper' do
      subject.get('/') { current_user }
      expect { get '/' }.to raise_error(NameError)

      described_class.before_each do |endpoint|
        allow(endpoint).to receive(:current_user).and_return('Bob')
      end

      get '/'
      expect(last_response.body).to eq('Bob')

      described_class.before_each(nil)
      expect { get '/' }.to raise_error(NameError)
    end

    it 'is able to stack helper' do
      subject.get('/') do
        authenticate_user!
        current_user
      end
      expect { get '/' }.to raise_error(NameError)

      described_class.before_each do |endpoint|
        allow(endpoint).to receive(:current_user).and_return('Bob')
      end

      described_class.before_each do |endpoint|
        allow(endpoint).to receive(:authenticate_user!).and_return(true)
      end

      get '/'
      expect(last_response.body).to eq('Bob')

      described_class.before_each(nil)
      expect { get '/' }.to raise_error(NameError)
    end
  end

  describe '#initialize' do
    it 'takes a settings stack, options, and a block' do
      p = proc {}
      expect do
        described_class.new(Grape::Util::InheritableSetting.new, {
                              path: '/',
                              method: :get
                            }, &p)
      end.not_to raise_error
    end
  end

  it 'sets itself in the env upon call' do
    subject.get('/') { 'Hello world.' }
    get '/'
    expect(last_request.env[Grape::Env::API_ENDPOINT]).to be_a(described_class)
  end

  describe '#status' do
    it 'is callable from within a block' do
      subject.get('/home') do
        status 206
        'Hello'
      end

      get '/home'
      expect(last_response.status).to eq(206)
      expect(last_response.body).to eq('Hello')
    end

    it 'is set as default to 200 for get' do
      memoized_status = nil
      subject.get('/home') do
        memoized_status = status
        'Hello'
      end

      get '/home'
      expect(last_response.status).to eq(200)
      expect(memoized_status).to eq(200)
      expect(last_response.body).to eq('Hello')
    end

    it 'is set as default to 201 for post' do
      memoized_status = nil
      subject.post('/home') do
        memoized_status = status
        'Hello'
      end

      post '/home'
      expect(last_response.status).to eq(201)
      expect(memoized_status).to eq(201)
      expect(last_response.body).to eq('Hello')
    end

    context 'when rescue_from' do
      subject { last_request.env[Grape::Env::API_ENDPOINT].status }

      before do
        post '/'
      end

      context 'when :all blockless' do
        context 'when default_error_status is not set' do
          let(:app) do
            Class.new(Grape::API) do
              rescue_from :all

              post { raise StandardError }
            end
          end

          it { is_expected.to eq(last_response.status) }
        end

        context 'when default_error_status is set' do
          let(:app) do
            Class.new(Grape::API) do
              default_error_status 418
              rescue_from :all

              post { raise StandardError }
            end
          end

          it { is_expected.to eq(last_response.status) }
        end
      end

      context 'when :with' do
        let(:app) do
          Class.new(Grape::API) do
            helpers do
              def handle_argument_error
                error!("I'm a teapot!", 418)
              end
            end
            rescue_from ArgumentError, with: :handle_argument_error

            post { raise ArgumentError }
          end
        end

        it { is_expected.to eq(last_response.status) }
      end
    end
  end

  describe '#header' do
    it 'is callable from within a block' do
      subject.get('/hey') do
        header 'X-Awesome', 'true'
        'Awesome'
      end

      get '/hey'
      expect(last_response.headers['X-Awesome']).to eq('true')
    end
  end

  describe '#headers' do
    before do
      subject.get('/headers') do
        headers.to_json
      end
    end

    let(:headers) do
      Grape::Util::Header.new.tap do |h|
        h['Cookie'] = ''
        h['Host'] = 'example.org'
      end
    end

    it 'includes request headers' do
      get '/headers'
      expect(JSON.parse(last_response.body)).to include(headers.to_h)
    end

    it 'includes additional request headers' do
      get '/headers', nil, 'HTTP_X_GRAPE_CLIENT' => '1'
      x_grape_client_header = 'x-grape-client'
      expect(JSON.parse(last_response.body)[x_grape_client_header]).to eq('1')
    end
  end

  describe '#cookies' do
    it 'is callable from within a block' do
      subject.get('/get/cookies') do
        cookies['my-awesome-cookie1'] = 'is cool'
        cookies['my-awesome-cookie2'] = {
          value: 'is cool too',
          domain: 'my.example.com',
          path: '/',
          secure: true
        }
        cookies[:cookie3] = 'symbol'
        cookies['cookie4'] = 'secret code here'
      end

      get('/get/cookies')

      expect(last_response.cookie_jar).to contain_exactly(
        { 'name' => 'cookie3', 'value' => 'symbol' },
        { 'name' => 'cookie4', 'value' => 'secret code here' },
        { 'name' => 'my-awesome-cookie1', 'value' => 'is cool' },
        { 'name' => 'my-awesome-cookie2', 'value' => 'is cool too', 'domain' => 'my.example.com', 'path' => '/', 'secure' => true }
      )
    end

    it 'sets browser cookies and does not set response cookies' do
      set_cookie %w[username=mrplum sandbox=true]
      subject.get('/username') do
        cookies[:username]
      end

      get '/username'
      expect(last_response.body).to eq('mrplum')
      expect(last_response.cookie_jar).to be_empty
    end

    it 'sets and update browser cookies' do
      set_cookie %w[username=user sandbox=false]
      subject.get('/username') do
        cookies[:sandbox] = true if cookies[:sandbox] == 'false'
        cookies[:username] += '_test'
      end

      get '/username'
      expect(last_response.body).to eq('user_test')
      expect(last_response.cookie_jar).to contain_exactly(
        { 'name' => 'sandbox', 'value' => 'true' },
        { 'name' => 'username', 'value' => 'user_test' }
      )
    end

    it 'deletes cookie' do
      set_cookie %w[delete_this_cookie=1 and_this=2]
      subject.get('/test') do
        sum = 0
        cookies.each do |name, val|
          sum += val.to_i
          cookies.delete name
        end
        sum
      end
      get '/test'
      expect(last_response.body).to eq('3')
      expect(last_response.cookie_jar).to contain_exactly(
        { 'name' => 'and_this', 'value' => '', 'max-age' => 0, 'expires' => Time.at(0) },
        { 'name' => 'delete_this_cookie', 'value' => '', 'max-age' => 0, 'expires' => Time.at(0) }
      )
    end

    it 'deletes cookies with path' do
      set_cookie %w[delete_this_cookie=1 and_this=2]
      subject.get('/test') do
        sum = 0
        cookies.each do |name, val|
          sum += val.to_i
          cookies.delete name, path: '/test'
        end
        sum
      end
      get '/test'
      expect(last_response.body).to eq('3')
      expect(last_response.cookie_jar).to contain_exactly(
        { 'name' => 'and_this', 'path' => '/test', 'value' => '', 'max-age' => 0, 'expires' => Time.at(0) },
        { 'name' => 'delete_this_cookie', 'path' => '/test', 'value' => '', 'max-age' => 0, 'expires' => Time.at(0) }
      )
    end
  end

  describe '#params' do
    context 'default class' do
      it 'is a ActiveSupport::HashWithIndifferentAccess' do
        subject.get '/foo' do
          params.class
        end

        get '/foo'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('ActiveSupport::HashWithIndifferentAccess')
      end
    end

    context 'sets a value to params' do
      it 'params' do
        subject.params do
          requires :a, type: String
        end
        subject.get '/foo' do
          params[:a] = 'bar'
        end

        get '/foo', a: 'foo'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('bar')
      end
    end
  end

  describe '#params' do
    it 'is available to the caller' do
      subject.get('/hey') do
        params[:howdy]
      end

      get '/hey?howdy=hey'
      expect(last_response.body).to eq('hey')
    end

    it 'parses from path segments' do
      subject.get('/hey/:id') do
        params[:id]
      end

      get '/hey/12'
      expect(last_response.body).to eq('12')
    end

    it 'deeply converts nested params' do
      subject.get '/location' do
        params[:location][:city]
      end
      get '/location?location[city]=Dallas'
      expect(last_response.body).to eq('Dallas')
    end

    context 'with special requirements' do
      it 'parses email param with provided requirements for params' do
        subject.get('/:person_email', requirements: { person_email: /.*/ }) do
          params[:person_email]
        end

        get '/someone@example.com'
        expect(last_response.body).to eq('someone@example.com')

        get 'someone@example.com.pl'
        expect(last_response.body).to eq('someone@example.com.pl')
      end

      it 'parses many params with provided regexps' do
        subject.get('/:person_email/test/:number', requirements: { person_email: /someone@(.*).com/, number: /[0-9]/ }) do
          params[:person_email] << params[:number]
        end

        get '/someone@example.com/test/1'
        expect(last_response.body).to eq('someone@example.com1')

        get '/someone@testing.wrong/test/1'
        expect(last_response.status).to eq(404)

        get 'someone@test.com/test/wrong_number'
        expect(last_response.status).to eq(404)

        get 'someone@test.com/wrong_middle/1'
        expect(last_response.status).to eq(404)
      end

      context 'namespace requirements' do
        before do
          subject.namespace :outer, requirements: { person_email: /abc@(.*).com/ } do
            get('/:person_email') do
              params[:person_email]
            end

            namespace :inner, requirements: { number: /[0-9]/, person_email: /someone@(.*).com/ } do
              get '/:person_email/test/:number' do
                params[:person_email] << params[:number]
              end
            end
          end
        end

        it 'parse email param with provided requirements for params' do
          get '/outer/abc@example.com'
          expect(last_response.body).to eq('abc@example.com')
        end

        it "overrides outer namespace's requirements" do
          get '/outer/inner/someone@testing.wrong/test/1'
          expect(last_response.status).to eq(404)

          get '/outer/inner/someone@testing.com/test/1'
          expect(last_response.status).to eq(200)
          expect(last_response.body).to eq('someone@testing.com1')
        end
      end
    end

    context 'from body parameters' do
      before do
        subject.post '/request_body' do
          params[:user]
        end
        subject.put '/request_body' do
          params[:user]
        end
      end

      it 'converts JSON bodies to params' do
        post '/request_body', Grape::Json.dump(user: 'Bobby T.'), 'CONTENT_TYPE' => 'application/json'
        expect(last_response.body).to eq('Bobby T.')
      end

      it 'does not convert empty JSON bodies to params' do
        put '/request_body', '', 'CONTENT_TYPE' => 'application/json'
        expect(last_response.body).to eq('')
      end

      if Object.const_defined? :MultiXml
        it 'converts XML bodies to params' do
          post '/request_body', '<user>Bobby T.</user>', 'CONTENT_TYPE' => 'application/xml'
          expect(last_response.body).to eq('Bobby T.')
        end

        it 'converts XML bodies to params' do
          put '/request_body', '<user>Bobby T.</user>', 'CONTENT_TYPE' => 'application/xml'
          expect(last_response.body).to eq('Bobby T.')
        end
      else
        let(:body) { '<user>Bobby T.</user>' }

        it 'converts XML bodies to params' do
          post '/request_body', body, 'CONTENT_TYPE' => 'application/xml'
          expect(last_response.body).to eq(Grape::Xml.parse(body)['user'].to_s)
        end

        it 'converts XML bodies to params' do
          put '/request_body', body, 'CONTENT_TYPE' => 'application/xml'
          expect(last_response.body).to eq(Grape::Xml.parse(body)['user'].to_s)
        end
      end

      it 'does not include parameters not defined by the body' do
        subject.post '/omitted_params' do
          error! 400, 'expected nil' if params[:version]
          params[:user]
        end
        post '/omitted_params', Grape::Json.dump(user: 'Bob'), 'CONTENT_TYPE' => 'application/json'
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq('Bob')
      end

      # Rack swallowed this error until v2.2.0
      it 'returns a 400 if given an invalid multipart body', if: Gem::Version.new(Rack.release) >= Gem::Version.new('2.2.0') do
        subject.params do
          requires :file, type: Rack::Multipart::UploadedFile
        end
        subject.post '/upload' do
          params[:file][:filename]
        end
        post '/upload', { file: '' }, 'CONTENT_TYPE' => 'multipart/form-data; boundary=foobar'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('file is invalid')
      end
    end

    context 'when the limit on multipart files is exceeded' do
      around do |example|
        limit = Rack::Utils.multipart_part_limit
        Rack::Utils.multipart_part_limit = 1
        example.run
        Rack::Utils.multipart_part_limit = limit
      end

      it 'returns a 413 if given too many multipart files' do
        subject.params do
          requires :file, type: Rack::Multipart::UploadedFile
        end
        subject.post '/upload' do
          params[:file][:filename]
        end
        post '/upload', { file: Rack::Test::UploadedFile.new(__FILE__, 'text/plain'), extra: Rack::Test::UploadedFile.new(__FILE__, 'text/plain') }
        expect(last_response.status).to eq(413)
        expect(last_response.body).to eq("the number of uploaded files exceeded the system's configured limit (1)")
      end
    end

    it 'responds with a 415 for an unsupported content-type' do
      subject.format :json
      # subject.content_type :json, "application/json"
      subject.put '/request_body' do
        params[:user]
      end
      put '/request_body', '<user>Bobby T.</user>', 'CONTENT_TYPE' => 'application/xml'
      expect(last_response.status).to eq(415)
      expect(last_response.body).to eq('{"error":"The provided content-type \'application/xml\' is not supported."}')
    end

    it 'does not accept text/plain in JSON format if application/json is specified as content type' do
      subject.format :json
      subject.default_format :json
      subject.put '/request_body' do
        params[:user]
      end
      put '/request_body', Grape::Json.dump(user: 'Bob'), 'CONTENT_TYPE' => 'text/plain'

      expect(last_response.status).to eq(415)
      expect(last_response.body).to eq('{"error":"The provided content-type \'text/plain\' is not supported."}')
    end

    context 'content type with params' do
      before do
        subject.format :json
        subject.content_type :json, 'application/json; charset=utf-8'

        subject.post do
          params[:data]
        end
        post '/', Grape::Json.dump(data: { some: 'payload' }), 'CONTENT_TYPE' => 'application/json'
      end

      it 'does not response with 406 for same type without params' do
        expect(last_response.status).not_to be 406
      end

      it 'responses with given content type in headers' do
        expect(last_response.content_type).to eq 'application/json; charset=utf-8'
      end
    end

    context 'precedence' do
      before do
        subject.format :json
        subject.namespace '/:id' do
          get do
            {
              params: params[:id]
            }
          end
          post do
            {
              params: params[:id]
            }
          end
          put do
            {
              params: params[:id]
            }
          end
        end
      end

      it 'route string params have higher precedence than body params' do
        post '/123', { id: 456 }.to_json
        expect(JSON.parse(last_response.body)['params']).to eq '123'
        put '/123', { id: 456 }.to_json
        expect(JSON.parse(last_response.body)['params']).to eq '123'
      end

      it 'route string params have higher precedence than URL params' do
        get '/123?id=456'
        expect(JSON.parse(last_response.body)['params']).to eq '123'
        post '/123?id=456'
        expect(JSON.parse(last_response.body)['params']).to eq '123'
      end
    end

    context 'sets a value to params' do
      it 'params' do
        subject.params do
          requires :a, type: String
        end
        subject.get '/foo' do
          params[:a] = 'bar'
        end

        get '/foo', a: 'foo'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('bar')
      end
    end
  end

  describe '#error!' do
    it 'accepts a message' do
      subject.get('/hey') do
        error! 'This is not valid.'
        'This is valid.'
      end

      get '/hey'
      expect(last_response.status).to eq(500)
      expect(last_response.body).to eq('This is not valid.')
    end

    it 'accepts a code' do
      subject.get('/hey') do
        error! 'Unauthorized.', 401
      end

      get '/hey'
      expect(last_response.status).to eq(401)
      expect(last_response.body).to eq('Unauthorized.')
    end

    it 'accepts an object and render it in format' do
      subject.get '/hey' do
        error!({ 'dude' => 'rad' }, 403)
      end

      get '/hey.json'
      expect(last_response.status).to eq(403)
      expect(last_response.body).to eq('{"dude":"rad"}')
    end

    it 'accepts a frozen object' do
      subject.get '/hey' do
        error!({ 'dude' => 'rad' }.freeze, 403)
      end

      get '/hey.json'
      expect(last_response.status).to eq(403)
      expect(last_response.body).to eq('{"dude":"rad"}')
    end

    it 'can specifiy headers' do
      subject.get '/hey' do
        error!({ 'dude' => 'rad' }, 403, 'X-Custom' => 'value')
      end

      get '/hey.json'
      expect(last_response.status).to eq(403)
      expect(last_response.headers['X-Custom']).to eq('value')
    end

    it 'merges additional headers with headers set before call' do
      subject.before do
        header 'X-Before-Test', 'before-sample'
      end

      subject.get '/hey' do
        header 'X-Test', 'test-sample'
        error!({ 'dude' => 'rad' }, 403, 'X-Error' => 'error')
      end

      get '/hey.json'
      expect(last_response.headers['X-Before-Test']).to eq('before-sample')
      expect(last_response.headers['X-Test']).to eq('test-sample')
      expect(last_response.headers['X-Error']).to eq('error')
    end

    it 'does not merges additional headers with headers set after call' do
      subject.after do
        header 'X-After-Test', 'after-sample'
      end

      subject.get '/hey' do
        error!({ 'dude' => 'rad' }, 403, 'X-Error' => 'error')
      end

      get '/hey.json'
      expect(last_response.headers['X-Error']).to eq('error')
      expect(last_response.headers['X-After-Test']).to be_nil
    end

    it 'sets the status code for the endpoint' do
      memoized_endpoint = nil

      subject.get '/hey' do
        memoized_endpoint = self
        error!({ 'dude' => 'rad' }, 403, 'X-Custom' => 'value')
      end

      get '/hey.json'

      expect(memoized_endpoint.status).to eq(403)
    end
  end

  describe '#redirect' do
    it 'redirects to a url with status 302' do
      subject.get('/hey') do
        redirect '/ha'
      end
      get '/hey'
      expect(last_response.status).to eq 302
      expect(last_response.location).to eq '/ha'
      expect(last_response.body).to eq 'This resource has been moved temporarily to /ha.'
    end

    it 'has status code 303 if it is not get request and it is http 1.1' do
      subject.post('/hey') do
        redirect '/ha'
      end
      post '/hey', {}, 'HTTP_VERSION' => 'HTTP/1.1', 'SERVER_PROTOCOL' => 'HTTP/1.1'
      expect(last_response.status).to eq 303
      expect(last_response.location).to eq '/ha'
      expect(last_response.body).to eq 'An alternate resource is located at /ha.'
    end

    it 'support permanent redirect' do
      subject.get('/hey') do
        redirect '/ha', permanent: true
      end
      get '/hey'
      expect(last_response.status).to eq 301
      expect(last_response.location).to eq '/ha'
      expect(last_response.body).to eq 'This resource has been moved permanently to /ha.'
    end

    it 'allows for an optional redirect body override' do
      subject.get('/hey') do
        redirect '/ha', body: 'test body'
      end
      get '/hey'
      expect(last_response.body).to eq 'test body'
    end
  end

  describe 'NameError' do
    context 'when referencing an undefined local variable or method' do
      it 'raises NameError but stripping the internals of the Grape::Endpoint class and including the API route' do
        subject.get('/hey') { undefined_helper }
        expect { get '/hey' }.to raise_error(NameError, /^undefined local variable or method ['`]undefined_helper' for/)
      end
    end
  end

  it 'does not persist params between calls' do
    subject.post('/new') do
      params[:text]
    end

    post '/new', text: 'abc'
    expect(last_response.body).to eq('abc')

    post '/new', text: 'def'
    expect(last_response.body).to eq('def')
  end

  it 'resets all instance variables (except block) between calls' do
    subject.helpers do
      def memoized
        @memoized ||= params[:howdy]
      end
    end

    subject.get('/hello') do
      memoized
    end

    get '/hello?howdy=hey'
    expect(last_response.body).to eq('hey')
    get '/hello?howdy=yo'
    expect(last_response.body).to eq('yo')
  end

  it 'allows explicit return calls' do
    subject.get('/home') do
      return 'Hello'
    end

    expect(Grape.deprecator).to receive(:warn).with('Using `return` in an endpoint has been deprecated.')

    get '/home'
    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq('Hello')
  end

  context 'filters' do
    describe 'before filters' do
      it 'runs the before filter if set' do
        subject.before { env['before_test'] = 'OK' }
        subject.get('/before_test') { env['before_test'] }

        get '/before_test'
        expect(last_response.body).to eq('OK')
      end
    end

    describe 'after filters' do
      it 'overrides the response body if it sets it' do
        subject.after { body 'after' }
        subject.get('/after_test') { 'during' }
        get '/after_test'
        expect(last_response.body).to eq('after')
      end

      it 'does not override the response body with its return' do
        subject.after { 'after' }
        subject.get('/after_test') { 'body' }
        get '/after_test'
        expect(last_response.body).to eq('body')
      end
    end

    it 'allows adding to response with present' do
      subject.format :json
      subject.before { present :before, 'before' }
      subject.before_validation { present :before_validation, 'before_validation' }
      subject.after_validation { present :after_validation, 'after_validation' }
      subject.after { present :after, 'after' }
      subject.get :all_filters do
        present :endpoint, 'endpoint'
      end

      get '/all_filters'
      json = JSON.parse(last_response.body)
      expect(json.keys).to match_array %w[before before_validation after_validation endpoint after]
    end

    context 'when terminating the response with error!' do
      it 'breaks normal call chain' do
        called = []
        subject.before { called << 'before' }
        subject.before_validation { called << 'before_validation' }
        subject.after_validation { error! :oops, 500 }
        subject.after { called << 'after' }
        subject.get :error_filters do
          called << 'endpoint'
          ''
        end

        get '/error_filters'
        expect(last_response.status).to be 500
        expect(called).to match_array %w[before before_validation]
      end

      it 'allows prior and parent filters of same type to run' do
        called = []
        subject.before { called << 'parent' }
        subject.namespace :parent do
          before { called << 'prior' }

          before { error! :oops, 500 }

          before { called << 'subsequent' }

          get :hello do
            called << :endpoint
            'Hello!'
          end
        end

        get '/parent/hello'
        expect(last_response.status).to be 500
        expect(called).to match_array %w[parent prior]
      end
    end
  end

  context 'anchoring' do
    describe 'delete 204' do
      it 'allows for the anchoring option with a delete method' do
        subject.delete('/example', anchor: true)
        delete '/example/and/some/more'
        expect(last_response).to be_not_found
      end

      it 'anchors paths by default for the delete method' do
        subject.delete '/example'
        delete '/example/and/some/more'
        expect(last_response).to be_not_found
      end

      it 'responds to /example/and/some/more for the non-anchored delete method' do
        subject.delete '/example', anchor: false
        delete '/example/and/some/more'
        expect(last_response).to be_no_content
        expect(last_response.body).to be_empty
      end
    end

    describe 'delete 200, with response body' do
      it 'responds to /example/and/some/more for the non-anchored delete method' do
        subject.delete('/example', anchor: false) do
          status 200
          body 'deleted'
        end
        delete '/example/and/some/more'
        expect(last_response).to be_successful
        expect(last_response.body).not_to be_empty
      end
    end

    describe 'delete 200, with a return value (no explicit body)' do
      it 'responds to /example delete method' do
        subject.delete(:example) { 'deleted' }
        delete '/example'
        expect(last_response.status).to be 200
        expect(last_response.body).not_to be_empty
      end
    end

    describe 'delete 204, with nil has return value (no explicit body)' do
      it 'responds to /example delete method' do
        subject.delete(:example) { nil }
        delete '/example'
        expect(last_response.status).to be 204
        expect(last_response.body).to be_empty
      end
    end

    describe 'delete 204, with empty array has return value (no explicit body)' do
      it 'responds to /example delete method' do
        subject.delete(:example) { '' }
        delete '/example'
        expect(last_response.status).to be 204
        expect(last_response.body).to be_empty
      end
    end

    describe 'all other' do
      %w[post get head put options patch].each do |verb|
        it "allows for the anchoring option with a #{verb.upcase} method" do
          subject.__send__(verb, '/example', anchor: true) do
            verb
          end
          __send__(verb, '/example/and/some/more')
          expect(last_response.status).to be 404
        end

        it "anchors paths by default for the #{verb.upcase} method" do
          subject.__send__(verb, '/example') do
            verb
          end
          __send__(verb, '/example/and/some/more')
          expect(last_response.status).to be 404
        end

        it "responds to /example/and/some/more for the non-anchored #{verb.upcase} method" do
          subject.__send__(verb, '/example', anchor: false) do
            verb
          end
          __send__(verb, '/example/and/some/more')
          expect(last_response.status).to eql verb == 'post' ? 201 : 200
          expect(last_response.body).to eql verb == 'head' ? '' : verb
        end
      end
    end
  end

  context 'request' do
    it 'is set to the url requested' do
      subject.get('/url') do
        request.url
      end
      get '/url'
      expect(last_response.body).to eq('http://example.org/url')
    end

    ['v1', :v1].each do |version|
      it "includes version #{version}" do
        subject.version version, using: :path
        subject.get('/url') do
          request.url
        end
        get "/#{version}/url"
        expect(last_response.body).to eq("http://example.org/#{version}/url")
      end
    end
    it 'includes prefix' do
      subject.version 'v1', using: :path
      subject.prefix 'api'
      subject.get('/url') do
        request.url
      end
      get '/api/v1/url'
      expect(last_response.body).to eq('http://example.org/api/v1/url')
    end
  end

  context 'version headers' do
    before do
      # NOTE: a 404 is returned instead of the 406 if cascade: false is not set.
      subject.version 'v1', using: :header, vendor: 'ohanapi', cascade: false
      subject.get '/test' do
        'Hello!'
      end
    end

    it 'result in a 406 response if they are invalid' do
      get '/test', {}, 'HTTP_ACCEPT' => 'application/vnd.ohanapi.v1+json'
      expect(last_response.status).to eq(406)
    end

    it 'result in a 406 response if they cannot be parsed' do
      get '/test', {}, 'HTTP_ACCEPT' => 'application/vnd.ohanapi.v1+json; version=1'
      expect(last_response.status).to eq(406)
    end
  end

  context 'binary' do
    before do
      subject.get do
        stream FileStreamer.new(__FILE__)
      end
    end

    it 'suports stream objects in response' do
      get '/'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq File.read(__FILE__)
    end
  end

  context 'validation errors' do
    before do
      subject.before do
        header['Access-Control-Allow-Origin'] = '*'
      end
      subject.params do
        requires :id, type: String
      end
      subject.get do
        'should not get here'
      end
    end

    it 'returns the errors, and passes headers' do
      get '/'
      expect(last_response.status).to eq 400
      expect(last_response.body).to eq 'id is missing'
      expect(last_response.headers['Access-Control-Allow-Origin']).to eq('*')
    end
  end

  context 'instrumentation' do
    before do
      subject.before do
        # Placeholder
      end
      subject.get do
        'hello'
      end

      @events = []
      @subscriber = ActiveSupport::Notifications.subscribe(/grape/) do |*args|
        @events << ActiveSupport::Notifications::Event.new(*args)
      end
    end

    after do
      ActiveSupport::Notifications.unsubscribe(@subscriber)
    end

    it 'notifies AS::N' do
      get '/'

      # In order that the events finalized (time each block ended)
      expect(@events).to contain_exactly(
        have_attributes(name: 'endpoint_run_filters.grape', payload: { endpoint: a_kind_of(described_class),
                                                                       filters: a_collection_containing_exactly(an_instance_of(Proc)),
                                                                       type: :before }),
        have_attributes(name: 'endpoint_run_filters.grape', payload: { endpoint: a_kind_of(described_class),
                                                                       filters: [],
                                                                       type: :before_validation }),
        have_attributes(name: 'endpoint_run_validators.grape', payload: { endpoint: a_kind_of(described_class),
                                                                          validators: [],
                                                                          request: a_kind_of(Grape::Request) }),
        have_attributes(name: 'endpoint_run_filters.grape', payload: { endpoint: a_kind_of(described_class),
                                                                       filters: [],
                                                                       type: :after_validation }),
        have_attributes(name: 'endpoint_render.grape',      payload: { endpoint: a_kind_of(described_class) }),
        have_attributes(name: 'endpoint_run_filters.grape', payload: { endpoint: a_kind_of(described_class),
                                                                       filters: [],
                                                                       type: :after }),
        have_attributes(name: 'endpoint_run_filters.grape', payload: { endpoint: a_kind_of(described_class),
                                                                       filters: [],
                                                                       type: :finally }),
        have_attributes(name: 'endpoint_run.grape', payload: { endpoint: a_kind_of(described_class),
                                                               env: an_instance_of(Hash) }),
        have_attributes(name: 'format_response.grape', payload: { env: an_instance_of(Hash),
                                                                  formatter: a_kind_of(Module) })
      )

      # In order that events were initialized
      expect(@events.sort_by(&:time)).to contain_exactly(
        have_attributes(name: 'endpoint_run.grape', payload: { endpoint: a_kind_of(described_class),
                                                               env: an_instance_of(Hash) }),
        have_attributes(name: 'endpoint_run_filters.grape', payload: { endpoint: a_kind_of(described_class),
                                                                       filters: a_collection_containing_exactly(an_instance_of(Proc)),
                                                                       type: :before }),
        have_attributes(name: 'endpoint_run_filters.grape', payload: { endpoint: a_kind_of(described_class),
                                                                       filters: [],
                                                                       type: :before_validation }),
        have_attributes(name: 'endpoint_run_validators.grape', payload: { endpoint: a_kind_of(described_class),
                                                                          validators: [],
                                                                          request: a_kind_of(Grape::Request) }),
        have_attributes(name: 'endpoint_run_filters.grape', payload: { endpoint: a_kind_of(described_class),
                                                                       filters: [],
                                                                       type: :after_validation }),
        have_attributes(name: 'endpoint_render.grape',      payload: { endpoint: a_kind_of(described_class) }),
        have_attributes(name: 'endpoint_run_filters.grape', payload: { endpoint: a_kind_of(described_class),
                                                                       filters: [],
                                                                       type: :after }),
        have_attributes(name: 'endpoint_run_filters.grape', payload: { endpoint: a_kind_of(described_class),
                                                                       filters: [],
                                                                       type: :finally }),
        have_attributes(name: 'format_response.grape', payload: { env: an_instance_of(Hash),
                                                                  formatter: a_kind_of(Module) })
      )
    end
  end

  describe '#inspect' do
    subject { described_class.new(settings, options).inspect }

    let(:options) do
      {
        method: :path,
        path: '/path',
        app: {},
        route_options: { anchor: false },
        forward_match: true,
        for: Class.new
      }
    end
    let(:settings) { Grape::Util::InheritableSetting.new }

    it 'does not raise an error' do
      expect { subject }.not_to raise_error
    end
  end
end
