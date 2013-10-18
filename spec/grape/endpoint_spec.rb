require 'spec_helper'

describe Grape::Endpoint do
  subject { Class.new(Grape::API) }

  def app
    subject
  end

  describe '#initialize' do
    it 'takes a settings stack, options, and a block' do
      p = proc { }
      expect {
        Grape::Endpoint.new(Grape::Util::HashStack.new, {
          path: '/',
          method: :get
        }, &p)
      }.not_to raise_error
    end
  end

  it 'sets itself in the env upon call' do
    subject.get('/') { "Hello world." }
    get '/'
    last_request.env['api.endpoint'].should be_kind_of(Grape::Endpoint)
  end

  describe '#status' do
    it 'is callable from within a block' do
      subject.get('/home') do
        status 206
        "Hello"
      end

      get '/home'
      last_response.status.should == 206
      last_response.body.should == "Hello"
    end
  end

  describe '#header' do
    it 'is callable from within a block' do
      subject.get('/hey') do
        header 'X-Awesome', 'true'
        "Awesome"
      end

      get '/hey'
      last_response.headers['X-Awesome'].should == 'true'
    end
  end

  describe '#headers' do
    before do
      subject.get('/headers') do
        headers.to_json
      end
    end
    it 'includes request headers' do
      get '/headers'
      JSON.parse(last_response.body).should == {
        "Host" => "example.org",
        "Cookie" => ""
      }
    end
    it 'includes additional request headers' do
      get '/headers', nil, { "HTTP_X_GRAPE_CLIENT" => "1" }
      JSON.parse(last_response.body)["X-Grape-Client"].should == "1"
    end
    it 'includes headers passed as symbols' do
      env = Rack::MockRequest.env_for("/headers")
      env["HTTP_SYMBOL_HEADER".to_sym] = "Goliath passes symbols"
      body = subject.call(env)[2].body.first
      JSON.parse(body)["Symbol-Header"].should == "Goliath passes symbols"
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
            secure: true,
        }
        cookies[:cookie3] = 'symbol'
        cookies['cookie4'] = 'secret code here'
      end

      get('/get/cookies')

      last_response.headers['Set-Cookie'].split("\n").sort.should eql [
        "cookie3=symbol",
        "cookie4=secret+code+here",
        "my-awesome-cookie1=is+cool",
        "my-awesome-cookie2=is+cool+too; domain=my.example.com; path=/; secure"
     ]
    end

    it 'sets browser cookies and does not set response cookies' do
      subject.get('/username') do
        cookies[:username]
      end
      get('/username', {}, 'HTTP_COOKIE' => 'username=mrplum; sandbox=true')

      last_response.body.should == 'mrplum'
      last_response.headers['Set-Cookie'].should_not =~ /username=mrplum/
      last_response.headers['Set-Cookie'].should_not =~ /sandbox=true/
    end

    it 'sets and update browser cookies' do
      subject.get('/username') do
        cookies[:sandbox] = true if cookies[:sandbox] == 'false'
        cookies[:username] += "_test"
      end
      get('/username', {}, 'HTTP_COOKIE' => 'username=user; sandbox=false')
      last_response.body.should == 'user_test'
      last_response.headers['Set-Cookie'].should =~ /username=user_test/
      last_response.headers['Set-Cookie'].should =~ /sandbox=true/
    end

    it 'deletes cookie' do
      subject.get('/test') do
        sum = 0
        cookies.each do |name, val|
          sum += val.to_i
          cookies.delete name
        end
        sum
      end
      get '/test', {}, 'HTTP_COOKIE' => 'delete_this_cookie=1; and_this=2'
      last_response.body.should == '3'
      cookies = Hash[last_response.headers['Set-Cookie'].split("\n").map do |set_cookie|
        cookie = CookieJar::Cookie.from_set_cookie 'http://localhost/test', set_cookie
        [cookie.name, cookie]
      end]
      cookies.size.should == 2
      ["and_this", "delete_this_cookie"].each do |cookie_name|
        cookie = cookies[cookie_name]
        cookie.should_not be_nil
        cookie.value.should == "deleted"
        cookie.expired?.should be_true
      end
    end

    it 'deletes cookies with path' do
      subject.get('/test') do
        sum = 0
        cookies.each do |name, val|
          sum += val.to_i
          cookies.delete name, { path: '/test' }
        end
        sum
      end
      get('/test', {}, 'HTTP_COOKIE' => 'delete_this_cookie=1; and_this=2')
      last_response.body.should == '3'
      cookies = Hash[last_response.headers['Set-Cookie'].split("\n").map do |set_cookie|
        cookie = CookieJar::Cookie.from_set_cookie 'http://localhost/test', set_cookie
        [cookie.name, cookie]
      end]
      cookies.size.should == 2
      ["and_this", "delete_this_cookie"].each do |cookie_name|
        cookie = cookies[cookie_name]
        cookie.should_not be_nil
        cookie.value.should == "deleted"
        cookie.path.should == "/test"
        cookie.expired?.should be_true
      end
    end
  end

  describe '#declared' do
    before do
      subject.params do
        requires :first
        optional :second
        optional :third, default: 'third-default'
        group :nested do
          optional :fourth
        end
      end
    end

    it 'has as many keys as there are declared params' do
      subject.get '/declared' do
        declared(params).keys.size.should == 4
        ""
      end

      get '/declared?first=present'
      last_response.status.should == 200
    end

    it 'has a optional param with default value all the time' do
      subject.get '/declared' do
        params[:third].should == 'third-default'
        ""
      end

      get '/declared?first=one'
      last_response.status.should == 200
    end

    it 'builds nested params' do
      subject.get '/declared' do
        declared(params)[:nested].keys.size.should == 1
        ""
      end

      get '/declared?first=present&nested[fourth]=1'
      last_response.status.should == 200
    end

    it 'builds nested params when given array' do
      subject.get '/declared' do
        declared(params)[:nested].size.should == 2
        ""
      end

      get '/declared?first=present&nested[][fourth]=1&nested[][fourth]=2'
      last_response.status.should == 200
    end

    it 'filters out any additional params that are given' do
      subject.get '/declared' do
        declared(params).key?(:other).should == false
        ""
      end

      get '/declared?first=one&other=two'
      last_response.status.should == 200
    end

    it 'stringifies if that option is passed' do
      subject.get '/declared' do
        declared(params, stringify: true)["first"].should == "one"
        ""
      end

      get '/declared?first=one&other=two'
      last_response.status.should == 200
    end

    it 'does not include missing attributes if that option is passed' do
      subject.get '/declared' do
        error! 400, "expected nil" if declared(params, include_missing: false)[:second]
        ""
      end

      get '/declared?first=one&other=two'
      last_response.status.should == 200
    end
  end

  describe '#params' do
    it 'is available to the caller' do
      subject.get('/hey') do
        params[:howdy]
      end

      get '/hey?howdy=hey'
      last_response.body.should == 'hey'
    end

    it 'parses from path segments' do
      subject.get('/hey/:id') do
        params[:id]
      end

      get '/hey/12'
      last_response.body.should == '12'
    end

    it 'deeply converts nested params' do
      subject.get '/location' do
        params[:location][:city]
      end
      get '/location?location[city]=Dallas'
      last_response.body.should == 'Dallas'
    end

    context 'with special requirements' do
      it 'parses email param with provided requirements for params' do
        subject.get('/:person_email', requirements: { person_email: /.*/ }) do
          params[:person_email]
        end

        get '/someone@example.com'
        last_response.body.should == 'someone@example.com'

        get 'someone@example.com.pl'
        last_response.body.should == 'someone@example.com.pl'
      end

      it 'parses many params with provided regexps' do
        subject.get('/:person_email/test/:number', requirements: { person_email: /someone@(.*).com/, number: /[0-9]/ }) do
          params[:person_email] << params[:number]
        end

        get '/someone@example.com/test/1'
        last_response.body.should == 'someone@example.com1'

        get '/someone@testing.wrong/test/1'
        last_response.status.should == 404

        get 'someone@test.com/test/wrong_number'
        last_response.status.should == 404

        get 'someone@test.com/wrong_middle/1'
        last_response.status.should == 404
      end

      context 'namespace requirements' do
        before :each do
          subject.namespace :outer, requirements: { person_email: /abc@(.*).com/ } do
            get('/:person_email') do
              params[:person_email]
            end

            namespace :inner, requirements: { number: /[0-9]/, person_email: /someone@(.*).com/ }do
              get '/:person_email/test/:number' do
                params[:person_email] << params[:number]
              end
            end
          end
        end
        it "parse email param with provided requirements for params" do
          get '/outer/abc@example.com'
          last_response.body.should == 'abc@example.com'
        end

        it "should override outer namespace's requirements" do
          get '/outer/inner/someone@testing.wrong/test/1'
          last_response.status.should == 404

          get '/outer/inner/someone@testing.com/test/1'
          last_response.status.should == 200
          last_response.body.should == 'someone@testing.com1'
        end

      end
    end

    context 'from body parameters' do
      before(:each) do
        subject.post '/request_body' do
          params[:user]
        end
        subject.put '/request_body' do
          params[:user]
        end
      end

      it 'converts JSON bodies to params' do
        post '/request_body', MultiJson.dump(user: 'Bobby T.'), { 'CONTENT_TYPE' => 'application/json' }
        last_response.body.should == 'Bobby T.'
      end

      it 'does not convert empty JSON bodies to params' do
        put '/request_body', '', { 'CONTENT_TYPE' => 'application/json' }
        last_response.body.should == ''
      end

      it 'converts XML bodies to params' do
        post '/request_body', '<user>Bobby T.</user>', { 'CONTENT_TYPE' => 'application/xml' }
        last_response.body.should == 'Bobby T.'
      end

      it 'converts XML bodies to params' do
        put '/request_body', '<user>Bobby T.</user>', { 'CONTENT_TYPE' => 'application/xml' }
        last_response.body.should == 'Bobby T.'
      end

      it 'does not include parameters not defined by the body' do
        subject.post '/omitted_params' do
          error! 400, "expected nil" if params[:version]
          params[:user]
        end
        post '/omitted_params', MultiJson.dump(user: 'Bob'), { 'CONTENT_TYPE' => 'application/json' }
        last_response.status.should == 201
        last_response.body.should == "Bob"
      end
    end

    it "responds with a 406 for an unsupported content-type" do
      subject.format :json
      # subject.content_type :json, "application/json"
      subject.put '/request_body' do
        params[:user]
      end
      put '/request_body', '<user>Bobby T.</user>', { 'CONTENT_TYPE' => 'application/xml' }
      last_response.status.should == 406
      last_response.body.should == '{"error":"The requested content-type \'application/xml\' is not supported."}'
    end

  end

  describe '#error!' do
    it 'accepts a message' do
      subject.get('/hey') do
        error! "This is not valid."
        "This is valid."
      end

      get '/hey'
      last_response.status.should == 403
      last_response.body.should == "This is not valid."
    end

    it 'accepts a code' do
      subject.get('/hey') do
        error! "Unauthorized.", 401
      end

      get '/hey'
      last_response.status.should == 401
      last_response.body.should == "Unauthorized."
    end

    it 'accepts an object and render it in format' do
      subject.get '/hey' do
        error!({ 'dude' => 'rad' }, 403)
      end

      get '/hey.json'
      last_response.status.should == 403
      last_response.body.should == '{"dude":"rad"}'
    end
  end

  describe '#redirect' do
    it 'redirects to a url with status 302' do
      subject.get('/hey') do
        redirect "/ha"
      end
      get '/hey'
      last_response.status.should eq 302
      last_response.headers['Location'].should eq "/ha"
      last_response.body.should eq ""
    end

    it 'has status code 303 if it is not get request and it is http 1.1' do
      subject.post('/hey') do
        redirect "/ha"
      end
      post '/hey', {}, 'HTTP_VERSION' => 'HTTP/1.1'
      last_response.status.should eq 303
      last_response.headers['Location'].should eq "/ha"
    end

    it 'support permanent redirect' do
      subject.get('/hey') do
        redirect "/ha", permanent: true
      end
      get '/hey'
      last_response.status.should eq 301
      last_response.headers['Location'].should eq "/ha"
      last_response.body.should eq ""
    end
  end

  it 'does not persist params between calls' do
    subject.post('/new') do
      params[:text]
    end

    post '/new', text: 'abc'
    last_response.body.should == 'abc'

    post '/new', text: 'def'
    last_response.body.should == 'def'
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
    last_response.body.should == 'hey'
    get '/hello?howdy=yo'
    last_response.body.should == 'yo'
  end

  it 'allows explicit return calls' do
    subject.get('/home') do
      return "Hello"
    end

    get '/home'
    last_response.status.should == 200
    last_response.body.should == "Hello"
  end

  describe '.generate_api_method' do
    it 'raises NameError if the method name is already in use' do
      expect {
        Grape::Endpoint.generate_api_method("version", &proc { })
      }.to raise_error(NameError)
    end
    it 'raises ArgumentError if a block is not given' do
      expect {
        Grape::Endpoint.generate_api_method("GET without a block method")
      }.to raise_error(ArgumentError)
    end
    it 'returns a Proc' do
      Grape::Endpoint.generate_api_method("GET test for a proc", &proc { }).should be_a Proc
    end
  end

  context 'filters' do
    describe 'before filters' do
      it 'runs the before filter if set' do
        subject.before { env['before_test'] = "OK" }
        subject.get('/before_test') { env['before_test'] }

        get '/before_test'
        last_response.body.should == "OK"
      end
    end

    describe 'after filters' do
      it 'overrides the response body if it sets it' do
        subject.after { body "after" }
        subject.get('/after_test') { "during" }
        get '/after_test'
        last_response.body.should == 'after'
      end

      it 'does not override the response body with its return' do
        subject.after { "after" }
        subject.get('/after_test') { "body" }
        get '/after_test'
        last_response.body.should == "body"
      end
    end
  end

  context 'anchoring' do
    verbs = %w(post get head delete put options patch)

    verbs.each do |verb|
      it 'allows for the anchoring option with a #{verb.upcase} method' do
        subject.send(verb, '/example', anchor: true) do
          verb
        end
        send(verb, '/example/and/some/more')
        last_response.status.should eql 404
      end

      it 'anchors paths by default for the #{verb.upcase} method' do
        subject.send(verb, '/example') do
          verb
        end
        send(verb, '/example/and/some/more')
        last_response.status.should eql 404
      end

      it 'responds to /example/and/some/more for the non-anchored #{verb.upcase} method' do
        subject.send(verb, '/example', anchor: false) do
          verb
        end
        send(verb, '/example/and/some/more')
        last_response.status.should eql verb == "post" ? 201 : 200
        last_response.body.should eql verb == 'head' ? '' : verb
      end
    end
  end

  context 'request' do
    it 'should be set to the url requested' do
      subject.get('/url') do
        request.url
      end
      get '/url'
      last_response.body.should == "http://example.org/url"
    end
    ['v1', :v1].each do |version|
      it 'should include version #{version}' do
        subject.version version, using: :path
        subject.get('/url') do
          request.url
        end
        get "/#{version}/url"
        last_response.body.should == "http://example.org/#{version}/url"
      end
    end
    it 'should include prefix' do
      subject.version 'v1', using: :path
      subject.prefix 'api'
      subject.get('/url') do
        request.url
      end
      get '/api/v1/url'
      last_response.body.should == "http://example.org/api/v1/url"
    end
  end

end
