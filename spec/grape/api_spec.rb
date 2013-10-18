require 'spec_helper'
require 'shared/versioning_examples'

describe Grape::API do
  subject { Class.new(Grape::API) }

  def app
    subject
  end

  describe '.prefix' do

    it 'routes root through with the prefix' do
      subject.prefix 'awesome/sauce'
      subject.get do
        "Hello there."
      end

      get 'awesome/sauce/'
      last_response.body.should eql "Hello there."
    end

    it 'routes through with the prefix' do
      subject.prefix 'awesome/sauce'
      subject.get :hello do
        "Hello there."
      end

      get 'awesome/sauce/hello'
      last_response.body.should eql "Hello there."

      get '/hello'
      last_response.status.should eql 404
    end

  end

  describe '.version' do
    context 'when defined' do
      it 'returns version value' do
        subject.version 'v1'
        subject.version.should == 'v1'
      end
    end

    context 'when not defined' do
      it 'returns nil' do
        subject.version.should be_nil
      end
    end
  end

  describe '.version using path' do
    it_should_behave_like 'versioning' do
      let(:macro_options) do
        {
          using: :path
        }
      end
    end
  end

  describe '.version using param' do
    it_should_behave_like 'versioning' do
      let(:macro_options) do
        {
          using: :param,
          parameter: "apiver"
        }
      end
    end
  end

  describe '.version using header' do
    it_should_behave_like 'versioning' do
      let(:macro_options) do
        {
          using: :header,
          vendor: 'mycompany',
          format: 'json'
        }
      end
    end

    # Behavior as defined by rfc2616 when no header is defined
    # http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html
    describe 'no specified accept header' do
      # subject.version 'v1', using: :header
      # subject.get '/hello' do
      #   'hello'
      # end

      # it 'routes' do
      #   get '/hello'
      #   last_response.status.should eql 200
      # end
    end

    # pending 'routes if any media type is allowed'
  end

  describe '.version using accept_version_header' do
    it_should_behave_like 'versioning' do
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
      subject.settings[:representations][Object].should == klass
    end
  end

  describe '.namespace' do
    it 'is retrievable and converted to a path' do
      subject.namespace :awesome do
        namespace.should == '/awesome'
      end
    end

    it 'comes after the prefix and version' do
      subject.prefix :rad
      subject.version 'v1', using: :path

      subject.namespace :awesome do
        get('/hello') { "worked" }
      end

      get "/rad/v1/awesome/hello"
      last_response.body.should == "worked"
    end

    it 'cancels itself after the block is over' do
      subject.namespace :awesome do
        namespace.should == '/awesome'
      end

      subject.namespace.should == '/'
    end

    it 'is stackable' do
      subject.namespace :awesome do
        namespace :rad do
          namespace.should == '/awesome/rad'
        end
        namespace.should == '/awesome'
      end
      subject.namespace.should == '/'
    end

    it 'accepts path segments correctly' do
      subject.namespace :members do
        namespace '/:member_id' do
          namespace.should == '/members/:member_id'
          get '/' do
            params[:member_id]
          end
        end
      end
      get '/members/23'
      last_response.body.should == "23"
    end

    it 'is callable with nil just to push onto the stack' do
      subject.namespace do
        version 'v2', using: :path
        get('/hello') { "inner" }
      end
      subject.get('/hello') { "outer" }

      get '/v2/hello'
      last_response.body.should == "inner"
      get '/hello'
      last_response.body.should == "outer"
    end

    %w(group resource resources segment).each do |als|
      it '`.#{als}` is an alias' do
        subject.send(als, :awesome) do
          namespace.should ==  "/awesome"
        end
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
      last_response.body.should == '23'
    end

    it 'should be able to define requirements with a single hash' do
      subject.namespace :users do
        route_param :id, requirements: /[0-9]+/ do
          get do
            params[:id]
          end
        end
      end

      get '/users/michael'
      last_response.status.should == 404
      get '/users/23'
      last_response.status.should == 200
    end
  end

  describe '.route' do
    it 'allows for no path' do
      subject.namespace :votes do
        get do
          "Votes"
        end
        post do
          "Created a Vote"
        end
      end

      get '/votes'
      last_response.body.should eql 'Votes'
      post '/votes'
      last_response.body.should eql 'Created a Vote'
    end

    it 'handles empty calls' do
      subject.get "/"
      get "/"
      last_response.body.should eql ""
    end

    describe 'root routes should work with' do
      before do
        subject.format :txt
        def subject.enable_root_route!
          get("/") { "root" }
        end
      end

      after do
        last_response.body.should eql "root"
      end

      describe 'path versioned APIs' do
        before do
          subject.version 'v1', using: :path
          subject.enable_root_route!
        end

        it 'without a format' do
          versioned_get "/", "v1", using: :path
        end

        it 'with a format' do
          get "/v1/.json"
        end
      end

      it 'header versioned APIs' do
        subject.version 'v1', using: :header, vendor: 'test'
        subject.enable_root_route!

        versioned_get "/", "v1", using: :header, vendor: 'test'
      end

      it 'header versioned APIs with multiple headers' do
        subject.version ['v1', 'v2'], using: :header, vendor: 'test'
        subject.enable_root_route!

        versioned_get "/", "v1", using: :header, vendor: 'test'
        versioned_get "/", "v2", using: :header, vendor: 'test'
      end

      it 'param versioned APIs' do
        subject.version 'v1', using: :param
        subject.enable_root_route!

        versioned_get "/", "v1", using: :param
      end

      it 'Accept-Version header versioned APIs' do
        subject.version 'v1', using: :accept_version_header
        subject.enable_root_route!

        versioned_get "/", "v1", using: :accept_version_header
      end

      it 'unversioned APIs' do
        subject.enable_root_route!

        get "/"
      end
    end

    it 'allows for multiple paths' do
      subject.get(["/abc", "/def"]) do
        "foo"
      end

      get '/abc'
      last_response.body.should eql 'foo'
      get '/def'
      last_response.body.should eql 'foo'
    end

    context 'format' do
      before(:each) do
        subject.get("/abc") do
          RSpec::Mocks::Mock.new(to_json: 'abc', to_txt: 'def')
        end
      end

      it 'allows .json' do
        get '/abc.json'
        last_response.status.should == 200
        last_response.body.should eql 'abc' # json-encoded symbol
      end

      it 'allows .txt' do
        get '/abc.txt'
        last_response.status.should == 200
        last_response.body.should eql 'def' # raw text
      end
    end

    it 'allows for format without corrupting a param' do
      subject.get('/:id') do
        { "id" => params[:id] }
      end

      get '/awesome.json'
      last_response.body.should eql '{"id":"awesome"}'
    end

    it 'allows for format in namespace with no path' do
      subject.namespace :abc do
        get do
          ["json"]
        end
      end

      get '/abc.json'
      last_response.body.should eql '["json"]'
    end

    it 'allows for multiple verbs' do
      subject.route([:get, :post], '/abc') do
        "hiya"
      end

      subject.endpoints.first.routes.each do |route|
        route.route_path.should eql '/abc(.:format)'
      end

      get '/abc'
      last_response.body.should eql 'hiya'
      post '/abc'
      last_response.body.should eql 'hiya'
    end

    [:put, :post].each do |verb|
      context verb do
        ['string', :symbol, 1, -1.1, {}, [], true, false, nil].each do |object|
          it "allows a(n) #{object.class} json object in params" do
            subject.format :json
            subject.send(verb) do
              env['api.request.body']
            end
            send verb, '/', MultiJson.dump(object), { 'CONTENT_TYPE' => 'application/json' }
            last_response.status.should == (verb == :post ? 201 : 200)
            last_response.body.should eql MultiJson.dump(object)
            last_request.params.should eql Hash.new
          end
          it "stores input in api.request.input" do
            subject.format :json
            subject.send(verb) do
              env['api.request.input']
            end
            send verb, '/', MultiJson.dump(object), { 'CONTENT_TYPE' => 'application/json' }
            last_response.status.should == (verb == :post ? 201 : 200)
            last_response.body.should eql MultiJson.dump(object).to_json
          end
          context "chunked transfer encoding" do
            it "stores input in api.request.input" do
              subject.format :json
              subject.send(verb) do
                env['api.request.input']
              end
              send verb, '/', MultiJson.dump(object), { 'CONTENT_TYPE' => 'application/json', 'HTTP_TRANSFER_ENCODING' => 'chunked', 'CONTENT_LENGTH' => nil  }
              last_response.status.should == (verb == :post ? 201 : 200)
              last_response.body.should eql MultiJson.dump(object).to_json
            end
          end
        end
      end
    end

    it 'allows for multipart paths' do

      subject.route([:get, :post], '/:id/first') do
        "first"
      end

      subject.route([:get, :post], '/:id') do
        "ola"
      end
      subject.route([:get, :post], '/:id/first/second') do
        "second"
      end

      get '/1'
      last_response.body.should eql 'ola'
      post '/1'
      last_response.body.should eql 'ola'
      get '/1/first'
      last_response.body.should eql 'first'
      post '/1/first'
      last_response.body.should eql 'first'
      get '/1/first/second'
      last_response.body.should eql 'second'

    end

    it 'allows for :any as a verb' do
      subject.route(:any, '/abc') do
        "lol"
      end

      %w(get post put delete options patch).each do |m|
        send(m, '/abc')
        last_response.body.should eql 'lol'
      end
    end

    verbs = %w(post get head delete put options patch)
    verbs.each do |verb|
      it 'allows and properly constrain a #{verb.upcase} method' do
        subject.send(verb, '/example') do
          verb
        end
        send(verb, '/example')
        last_response.body.should eql verb == 'head' ? '' : verb
        # Call it with a method other than the properly constrained one.
        send(used_verb = verbs[(verbs.index(verb) + 2) % verbs.size], '/example')
        last_response.status.should eql used_verb == 'options' ? 204 : 405
      end
    end

    it 'returns a 201 response code for POST by default' do
      subject.post('example') do
        "Created"
      end

      post '/example'
      last_response.status.should eql 201
      last_response.body.should eql 'Created'
    end

    it 'returns a 405 for an unsupported method' do
      subject.get 'example' do
        "example"
      end
      put '/example'
      last_response.status.should eql 405
      last_response.body.should eql ''
    end

    specify '405 responses includes an Allow header specifying supported methods' do
      subject.get 'example' do
        "example"
      end
      subject.post 'example' do
        "example"
      end
      put '/example'
      last_response.headers['Allow'].should eql 'OPTIONS, GET, POST, HEAD'
    end

    specify '405 responses includes an Content-Type header' do
      subject.get 'example' do
        "example"
      end
      subject.post 'example' do
        "example"
      end
      put '/example'
      last_response.headers['Content-Type'].should eql 'text/plain'
    end

    it 'adds an OPTIONS route that returns a 204 and an Allow header' do
      subject.get 'example' do
        "example"
      end
      options '/example'
      last_response.status.should eql 204
      last_response.body.should eql ''
      last_response.headers['Allow'].should eql 'OPTIONS, GET, HEAD'
    end

    it 'allows HEAD on a GET request' do
      subject.get 'example' do
        "example"
      end
      head '/example'
      last_response.status.should eql 200
      last_response.body.should eql ''
    end

    it 'overwrites the default HEAD request' do
      subject.head 'example' do
        error! 'nothing to see here', 400
      end
      subject.get 'example' do
        "example"
      end
      head '/example'
      last_response.status.should eql 400
    end
  end

  context "do_not_route_head!" do
    before :each do
      subject.do_not_route_head!
      subject.get 'example' do
        "example"
      end
    end
    it 'options does not contain HEAD' do
      options '/example'
      last_response.status.should eql 204
      last_response.body.should eql ''
      last_response.headers['Allow'].should eql 'OPTIONS, GET'
    end
    it 'does not allow HEAD on a GET request' do
      head '/example'
      last_response.status.should eql 405
    end
  end

  context "do_not_route_options!" do
    before :each do
      subject.do_not_route_options!
      subject.get 'example' do
        "example"
      end
    end
    it 'options does not exist' do
      options '/example'
      last_response.status.should eql 405
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
      last_response.body.should eql 'first second'
    end

    it 'adds a after_validation filter' do
      subject.after_validation { @foo = "first #{params[:id] }:#{params[:id].class}"  }
      subject.after_validation { @bar = 'second' }
      subject.params do
        requires :id, type: Integer
      end
      subject.get '/' do
        "#{@foo} #{@bar}"
      end

      get '/', id: "32"
      last_response.body.should eql 'first 32:Fixnum second'
    end

    it 'adds a after filter' do
      m = double('after mock')
      subject.after { m.do_something! }
      subject.after { m.do_something! }
      subject.get '/' do
        @var ||= 'default'
      end

      m.should_receive(:do_something!).exactly(2).times
      get '/'
      last_response.body.should eql 'default'
    end
  end

  context 'format' do
    before do
      subject.get("/foo") { "bar" }
    end

    it 'sets content type for txt format' do
      get '/foo'
      last_response.headers['Content-Type'].should eql 'text/plain'
    end

    it 'sets content type for json' do
      get '/foo.json'
      last_response.headers['Content-Type'].should eql 'application/json'
    end

    it 'sets content type for error' do
      subject.get('/error') { error!('error in plain text', 500) }
      get '/error'
      last_response.headers['Content-Type'].should eql 'text/plain'
    end

    it 'sets content type for error' do
      subject.format :json
      subject.get('/error') { error!('error in json', 500) }
      get '/error.json'
      last_response.headers['Content-Type'].should eql 'application/json'
    end

    it 'sets content type for xml' do
      subject.format :xml
      subject.get('/error') { error!('error in xml', 500) }
      get '/error.xml'
      last_response.headers['Content-Type'].should eql 'application/xml'
    end
  end

  context 'custom middleware' do
    module ApiSpec
      class PhonyMiddleware
        def initialize(app, *args)
          @args = args
          @app = app
          @block = true if block_given?
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
        settings = Grape::Util::HashStack.new
        settings.stub(:stack).and_return([{ middleware: [[ApiSpec::PhonyMiddleware, 'abc', 123]] }])
        subject.stub(:settings).and_return(settings)
        subject.middleware.should eql [[ApiSpec::PhonyMiddleware, 'abc', 123]]
      end

      it 'includes all middleware from stacked settings' do
        settings = Grape::Util::HashStack.new
        settings.stub(:stack).and_return [
          { middleware: [[ApiSpec::PhonyMiddleware, 123], [ApiSpec::PhonyMiddleware, 'abc']] },
          { middleware: [[ApiSpec::PhonyMiddleware, 'foo']] }
        ]

        subject.stub(:settings).and_return(settings)

        subject.middleware.should eql [
          [ApiSpec::PhonyMiddleware, 123],
          [ApiSpec::PhonyMiddleware, 'abc'],
          [ApiSpec::PhonyMiddleware, 'foo']
        ]
      end
    end

    describe '.use' do
      it 'adds middleware' do
        subject.use ApiSpec::PhonyMiddleware, 123
        subject.middleware.should eql [[ApiSpec::PhonyMiddleware, 123]]
      end

      it 'does not show up outside the namespace' do
        subject.use ApiSpec::PhonyMiddleware, 123
        subject.namespace :awesome do
          use ApiSpec::PhonyMiddleware, 'abc'
          middleware.should == [[ApiSpec::PhonyMiddleware, 123], [ApiSpec::PhonyMiddleware, 'abc']]
        end

        subject.middleware.should eql [[ApiSpec::PhonyMiddleware, 123]]
      end

      it 'calls the middleware' do
        subject.use ApiSpec::PhonyMiddleware, 'hello'
        subject.get '/' do
          env['phony.args'].first.first
        end

        get '/'
        last_response.body.should eql 'hello'
      end

      it 'adds a block if one is given' do
        block = lambda { }
        subject.use ApiSpec::PhonyMiddleware, &block
        subject.middleware.should eql [[ApiSpec::PhonyMiddleware, block]]
      end

      it 'uses a block if one is given' do
        block = lambda { }
        subject.use ApiSpec::PhonyMiddleware, &block
        subject.get '/' do
          env['phony.block'].inspect
        end

        get '/'
        last_response.body.should == 'true'
      end

      it 'does not destroy the middleware settings on multiple runs' do
        block = lambda { }
        subject.use ApiSpec::PhonyMiddleware, &block
        subject.get '/' do
          env['phony.block'].inspect
        end

        2.times do
          get '/'
          last_response.body.should == 'true'
        end
      end

      it 'mounts behind error middleware' do
        m = Class.new(Grape::Middleware::Base) do
          def before
            throw :error, message: "Caught in the Net", status: 400
          end
        end
        subject.use m
        subject.get "/" do
        end
        get "/"
        last_response.status.should == 400
        last_response.body.should == "Caught in the Net"
      end
    end
  end
  describe '.basic' do
    it 'protects any resources on the same scope' do
      subject.http_basic do |u, p|
        u == 'allow'
      end
      subject.get(:hello) { "Hello, world." }
      get '/hello'
      last_response.status.should eql 401
      get '/hello', {}, 'HTTP_AUTHORIZATION' => encode_basic_auth('allow', 'whatever')
      last_response.status.should eql 200
    end

    it 'is scopable' do
      subject.get(:hello) { "Hello, world." }
      subject.namespace :admin do
        http_basic do |u, p|
          u == 'allow'
        end

        get(:hello) { "Hello, world." }
      end

      get '/hello'
      last_response.status.should eql 200
      get '/admin/hello'
      last_response.status.should eql 401
    end

    it 'is callable via .auth as well' do
      subject.auth :http_basic do |u, p|
        u == 'allow'
      end

      subject.get(:hello) { "Hello, world." }
      get '/hello'
      last_response.status.should eql 401
      get '/hello', {}, 'HTTP_AUTHORIZATION' => encode_basic_auth('allow', 'whatever')
      last_response.status.should eql 200
    end
  end

  describe '.logger' do
    it 'returns an instance of Logger class by default' do
      subject.logger.class.should eql Logger
    end

    it 'allows setting a custom logger' do
      mylogger = Class.new
      subject.logger mylogger
      mylogger.should_receive(:info).exactly(1).times
      subject.logger.info "this will be logged"
    end

    it "defaults to a standard logger log format" do
      t = Time.at(100)
      Time.stub(:now).and_return(t)
      STDOUT.should_receive(:write).with("I, [#{Logger::Formatter.new.send(:format_datetime, t)}\##{Process.pid}]  INFO -- : this will be logged\n")
      subject.logger.info "this will be logged"
    end
  end

  describe '.helpers' do
    it 'is accessible from the endpoint' do
      subject.helpers do
        def hello
          "Hello, world."
        end
      end

      subject.get '/howdy' do
        hello
      end

      get '/howdy'
      last_response.body.should eql 'Hello, world.'
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
      last_response.body.should eql 'always there:false'
      get '/admin/secret'
      last_response.body.should eql 'always there:only in admin'
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

      lambda { get '/howdy' }.should_not raise_error
    end

    it 'allows for modules' do
      mod = Module.new do
        def hello
          "Hello, world."
        end
      end
      subject.helpers mod

      subject.get '/howdy' do
        hello
      end

      get '/howdy'
      last_response.body.should eql 'Hello, world.'
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
      lambda { get '/howdy' }.should_not raise_error
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
      last_response.status.should eql 404
      get '/legacy/abc'
      last_response.status.should eql 200
      get '/legacy/def'
      last_response.status.should eql 404
      get '/new/def'
      last_response.status.should eql 200
    end
  end

  describe '.rescue_from' do
    it 'does not rescue errors when rescue_from is not set' do
      subject.get '/exception' do
        raise "rain!"
      end
      lambda { get '/exception' }.should raise_error
    end

    it 'rescues all errors if rescue_from :all is called' do
      subject.rescue_from :all
      subject.get '/exception' do
        raise "rain!"
      end
      get '/exception'
      last_response.status.should eql 403
    end

    it 'rescues only certain errors if rescue_from is called with specific errors' do
      subject.rescue_from ArgumentError
      subject.get('/rescued') { raise ArgumentError }
      subject.get('/unrescued') { raise "beefcake" }

      get '/rescued'
      last_response.status.should eql 403

      lambda { get '/unrescued' }.should raise_error
    end

    it 'does not re-raise exceptions of type Grape::Exception::Base' do
      class CustomError < Grape::Exceptions::Base; end
      subject.get('/custom_exception') { raise CustomError }

      lambda { get '/custom_exception' }.should_not raise_error
    end

    it 'rescues custom grape exceptions' do
      class CustomError < Grape::Exceptions::Base; end
      subject.rescue_from CustomError do |e|
        rack_response('New Error', e.status)
      end
      subject.get '/custom_error' do
        raise CustomError, status: 400, message: 'Custom Error'
      end

      get '/custom_error'
      last_response.status.should == 400
      last_response.body.should == 'New Error'
    end

    it 'can rescue exceptions raised in the formatter' do
      formatter = double(:formatter)
      formatter.stub(:call) { raise StandardError }
      Grape::Formatter::Base.stub(:formatter_for) { formatter }

      subject.rescue_from :all do |e|
        rack_response('Formatter Error', 500)
      end
      subject.get('/formatter_exception') { 'Hello world' }

      get '/formatter_exception'
      last_response.status.should eql 500
      last_response.body.should == 'Formatter Error'
    end
  end

  describe '.rescue_from klass, block' do
    it 'rescues Exception' do
      subject.rescue_from RuntimeError do |e|
        rack_response("rescued from #{e.message}", 202)
      end
      subject.get '/exception' do
        raise "rain!"
      end
      get '/exception'
      last_response.status.should eql 202
      last_response.body.should == 'rescued from rain!'
    end
    it 'rescues an error via rescue_from :all' do
      class ConnectionError < RuntimeError; end
      subject.rescue_from :all do |e|
        rack_response("rescued from #{e.class.name}", 500)
      end
      subject.get '/exception' do
        raise ConnectionError
      end
      get '/exception'
      last_response.status.should eql 500
      last_response.body.should == 'rescued from ConnectionError'
    end
    it 'rescues a specific error' do
      class ConnectionError < RuntimeError; end
      subject.rescue_from ConnectionError do |e|
        rack_response("rescued from #{e.class.name}", 500)
      end
      subject.get '/exception' do
        raise ConnectionError
      end
      get '/exception'
      last_response.status.should eql 500
      last_response.body.should == 'rescued from ConnectionError'
    end
    it 'rescues multiple specific errors' do
      class ConnectionError < RuntimeError; end
      class DatabaseError < RuntimeError; end
      subject.rescue_from ConnectionError do |e|
        rack_response("rescued from #{e.class.name}", 500)
      end
      subject.rescue_from DatabaseError do |e|
        rack_response("rescued from #{e.class.name}", 500)
      end
      subject.get '/connection' do
        raise ConnectionError
      end
      subject.get '/database' do
        raise DatabaseError
      end
      get '/connection'
      last_response.status.should eql 500
      last_response.body.should == 'rescued from ConnectionError'
      get '/database'
      last_response.status.should eql 500
      last_response.body.should == 'rescued from DatabaseError'
    end
    it 'does not rescue a different error' do
      class CommunicationError < RuntimeError; end
      subject.rescue_from RuntimeError do |e|
        rack_response("rescued from #{e.class.name}", 500)
      end
      subject.get '/uncaught' do
        raise CommunicationError
      end
      lambda { get '/uncaught' }.should raise_error(CommunicationError)
    end
  end

  describe '.rescue_from klass, lambda' do
    it 'rescues an error with the lambda' do
      subject.rescue_from ArgumentError, lambda {
        rack_response("rescued with a lambda", 400)
      }
      subject.get('/rescue_lambda') { raise ArgumentError }

      get '/rescue_lambda'
      last_response.status.should == 400
      last_response.body.should == "rescued with a lambda"
    end

    it 'can execute the lambda with an argument' do
      subject.rescue_from ArgumentError, lambda { |e|
        rack_response(e.message, 400)
      }
      subject.get('/rescue_lambda') { raise ArgumentError, 'lambda takes an argument' }

      get '/rescue_lambda'
      last_response.status.should == 400
      last_response.body.should == 'lambda takes an argument'
    end
  end

  describe '.rescue_from klass, with: method' do
    it 'rescues an error with the specified message' do
      def rescue_arg_error
        Rack::Response.new('rescued with a method', 400)
      end

      subject.rescue_from ArgumentError, with: rescue_arg_error
      subject.get('/rescue_method') { raise ArgumentError }

      get '/rescue_method'
      last_response.status.should == 400
      last_response.body.should == 'rescued with a method'
    end
  end

  describe '.error_format' do
    it 'rescues all errors and return :txt' do
      subject.rescue_from :all
      subject.format :txt
      subject.get '/exception' do
        raise "rain!"
      end
      get '/exception'
      last_response.body.should eql "rain!"
    end

    it 'rescues all errors and return :txt with backtrace' do
      subject.rescue_from :all, backtrace: true
      subject.format :txt
      subject.get '/exception' do
        raise "rain!"
      end
      get '/exception'
      last_response.body.start_with?("rain!\r\n").should be_true
    end

    it 'rescues all errors with a default formatter' do
      subject.default_format :foo
      subject.content_type :foo, "text/foo"
      subject.rescue_from :all
      subject.get '/exception' do
        raise "rain!"
      end
      get '/exception.foo'
      last_response.body.should start_with "rain!"
    end

    it 'defaults the error formatter to format' do
      subject.format :json
      subject.rescue_from :all
      subject.content_type :json, "application/json"
      subject.content_type :foo, "text/foo"
      subject.get '/exception' do
        raise "rain!"
      end
      get '/exception.json'
      last_response.body.should == '{"error":"rain!"}'
      get '/exception.foo'
      last_response.body.should == '{"error":"rain!"}'
    end

    context 'class' do
      before :each do
        class CustomErrorFormatter
          def self.call(message, backtrace, options, env)
            "message: #{message} @backtrace"
          end
        end
      end
      it 'returns a custom error format' do
        subject.rescue_from :all, backtrace: true
        subject.error_formatter :txt, CustomErrorFormatter
        subject.get '/exception' do
          raise "rain!"
        end
        get '/exception'
        last_response.body.should == "message: rain! @backtrace"
      end
    end

    describe 'with' do
      context 'class' do
        before :each do
          class CustomErrorFormatter
            def self.call(message, backtrace, option, env)
              "message: #{message} @backtrace"
            end
          end
        end

        it 'returns a custom error format' do
          subject.rescue_from :all, backtrace: true
          subject.error_formatter :txt, with: CustomErrorFormatter
          subject.get('/exception') { raise "rain!" }

          get '/exception'
          last_response.body.should == 'message: rain! @backtrace'
        end
      end
    end

    it 'rescues all errors and return :json' do
      subject.rescue_from :all
      subject.format :json
      subject.get '/exception' do
        raise "rain!"
      end
      get '/exception'
      last_response.body.should eql '{"error":"rain!"}'
    end
    it 'rescues all errors and return :json with backtrace' do
      subject.rescue_from :all, backtrace: true
      subject.format :json
      subject.get '/exception' do
        raise "rain!"
      end
      get '/exception'
      json = MultiJson.load(last_response.body)
      json["error"].should eql 'rain!'
      json["backtrace"].length.should > 0
    end
    it 'rescues error! and return txt' do
      subject.format :txt
      subject.get '/error' do
        error!("Access Denied", 401)
      end
      get '/error'
      last_response.body.should eql "Access Denied"
    end
    it 'rescues error! and return json' do
      subject.format :json
      subject.get '/error' do
        error!("Access Denied", 401)
      end
      get '/error'
      last_response.body.should eql '{"error":"Access Denied"}'
    end
  end

  describe '.content_type' do
    it 'sets additional content-type' do
      subject.content_type :xls, "application/vnd.ms-excel"
      subject.get :excel do
        "some binary content"
      end
      get '/excel.xls'
      last_response.content_type.should == "application/vnd.ms-excel"
    end
    it 'allows to override content-type' do
      subject.get :content do
        content_type "text/javascript"
        "var x = 1;"
      end
      get '/content'
      last_response.content_type.should == "text/javascript"
    end
    it 'removes existing content types' do
      subject.content_type :xls, "application/vnd.ms-excel"
      subject.get :excel do
        "some binary content"
      end
      get '/excel.json'
      last_response.status.should == 406
      last_response.body.should == "The requested format 'txt' is not supported."
    end
  end

  describe '.formatter' do
    context 'multiple formatters' do
      before :each do
        subject.formatter :json, lambda { |object, env| "{\"custom_formatter\":\"#{object[:some] }\"}" }
        subject.formatter :txt, lambda { |object, env| "custom_formatter: #{object[:some] }" }
        subject.get :simple do
          { some: 'hash' }
        end
      end
      it 'sets one formatter' do
        get '/simple.json'
        last_response.body.should eql '{"custom_formatter":"hash"}'
      end
      it 'sets another formatter' do
        get '/simple.txt'
        last_response.body.should eql 'custom_formatter: hash'
      end
    end
    context 'custom formatter' do
      before :each do
        subject.content_type :json, 'application/json'
        subject.content_type :custom, 'application/custom'
        subject.formatter :custom, lambda { |object, env| "{\"custom_formatter\":\"#{object[:some] }\"}" }
        subject.get :simple do
          { some: 'hash' }
        end
      end
      it 'uses json' do
        get '/simple.json'
        last_response.body.should eql '{"some":"hash"}'
      end
      it 'uses custom formatter' do
        get '/simple.custom', { 'HTTP_ACCEPT' => 'application/custom' }
        last_response.body.should eql '{"custom_formatter":"hash"}'
      end
    end
    context 'custom formatter class' do
      module CustomFormatter
        def self.call(object, env)
          "{\"custom_formatter\":\"#{object[:some] }\"}"
        end
      end
      before :each do
        subject.content_type :json, 'application/json'
        subject.content_type :custom, 'application/custom'
        subject.formatter :custom, CustomFormatter
        subject.get :simple do
          { some: 'hash' }
        end
      end
      it 'uses json' do
        get '/simple.json'
        last_response.body.should eql '{"some":"hash"}'
      end
      it 'uses custom formatter' do
        get '/simple.custom', { 'HTTP_ACCEPT' => 'application/custom' }
        last_response.body.should eql '{"custom_formatter":"hash"}'
      end
    end
  end

  describe '.parser' do
    it 'parses data in format requested by content-type' do
      subject.format :json
      subject.post '/data' do
        { x: params[:x] }
      end
      post "/data", '{"x":42}', { 'CONTENT_TYPE' => 'application/json' }
      last_response.status.should == 201
      last_response.body.should == '{"x":42}'
    end
    context 'lambda parser' do
      before :each do
        subject.content_type :txt, "text/plain"
        subject.content_type :custom, "text/custom"
        subject.parser :custom, lambda { |object, env| { object.to_sym => object.to_s.reverse } }
        subject.put :simple do
          params[:simple]
        end
      end
      ["text/custom", "text/custom; charset=UTF-8"].each do |content_type|
        it "uses parser for #{content_type}" do
          put '/simple', "simple", "CONTENT_TYPE" => content_type
          last_response.status.should == 200
          last_response.body.should eql "elpmis"
        end
      end
    end
    context 'custom parser class' do
      module CustomParser
        def self.call(object, env)
          { object.to_sym => object.to_s.reverse }
        end
      end
      before :each do
        subject.content_type :txt, "text/plain"
        subject.content_type :custom, "text/custom"
        subject.parser :custom, CustomParser
        subject.put :simple do
          params[:simple]
        end
      end
      it 'uses custom parser' do
        put '/simple', "simple", "CONTENT_TYPE" => "text/custom"
        last_response.status.should == 200
        last_response.body.should eql "elpmis"
      end
    end
    context "multi_xml" do
      it "doesn't parse yaml" do
        subject.put :yaml do
          params[:tag]
        end
        put '/yaml', '<tag type="symbol">a123</tag>', "CONTENT_TYPE" => "application/xml"
        last_response.status.should == 400
        last_response.body.should eql 'Disallowed type attribute: "symbol"'
      end
    end
    context "none parser class" do
      before :each do
        subject.parser :json, nil
        subject.put "data" do
          "body: #{env['api.request.body'] }"
        end
      end
      it "does not parse data" do
        put '/data', 'not valid json', "CONTENT_TYPE" => "application/json"
        last_response.status.should == 200
        last_response.body.should == "body: not valid json"
      end
    end
  end

  describe '.default_format' do
    before :each do
      subject.format :json
      subject.default_format :json
    end
    it 'returns data in default format' do
      subject.get '/data' do
        { x: 42 }
      end
      get "/data"
      last_response.status.should == 200
      last_response.body.should == '{"x":42}'
    end
    it 'parses data in default format' do
      subject.post '/data' do
        { x: params[:x] }
      end
      post "/data", '{"x":42}', "CONTENT_TYPE" => ""
      last_response.status.should == 201
      last_response.body.should == '{"x":42}'
    end
  end

  describe '.default_error_status' do
    it 'allows setting default_error_status' do
      subject.rescue_from :all
      subject.default_error_status 200
      subject.get '/exception' do
        raise "rain!"
      end
      get '/exception'
      last_response.status.should eql 200
    end
    it 'has a default error status' do
      subject.rescue_from :all
      subject.get '/exception' do
        raise "rain!"
      end
      get '/exception'
      last_response.status.should eql 403
    end
  end

  context 'routes' do
    describe 'empty api structure' do
      it 'returns an empty array of routes' do
        subject.routes.should == []
      end
    end
    describe 'single method api structure' do
      before(:each) do
        subject.get :ping do
          'pong'
        end
      end
      it 'returns one route' do
        subject.routes.size.should == 1
        route = subject.routes[0]
        route.route_version.should be_nil
        route.route_path.should == "/ping(.:format)"
        route.route_method.should == "GET"
      end
    end
    describe 'api structure with two versions and a namespace' do
      before :each do
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
        subject.version.should == 'v2'
      end
      it 'returns versions' do
        subject.versions.should == ['v1', 'v2']
      end
      it 'sets route paths' do
        subject.routes.size.should >= 2
        subject.routes[0].route_path.should == "/:version/version(.:format)"
        subject.routes[1].route_path.should == "/p/:version/n1/n2/version(.:format)"
      end
      it 'sets route versions' do
        subject.routes[0].route_version.should == 'v1'
        subject.routes[1].route_version.should == 'v2'
      end
      it 'sets a nested namespace' do
        subject.routes[1].route_namespace.should == "/n1/n2"
      end
      it 'sets prefix' do
        subject.routes[1].route_prefix.should == 'p'
      end
    end
    describe 'api structure with additional parameters' do
      before(:each) do
        subject.get 'split/:string', { params: { "token" => "a token" }, optional_params: { "limit" => "the limit" } } do
          params[:string].split(params[:token], (params[:limit] || 0).to_i)
        end
      end
      it 'splits a string' do
        get "/split/a,b,c.json", token: ','
        last_response.body.should == '["a","b","c"]'
      end
      it 'splits a string with limit' do
        get "/split/a,b,c.json", token: ',', limit: '2'
        last_response.body.should == '["a","b,c"]'
      end
      it 'sets route_params' do
        subject.routes.map { |route|
          { params: route.route_params, optional_params: route.route_optional_params }
        }.should eq [
          { params: { "string" => "", "token" => "a token" }, optional_params: { "limit" => "the limit" } }
      ]
      end
    end
  end

  context 'desc' do
    it 'empty array of routes' do
      subject.routes.should == []
    end
    it 'empty array of routes' do
      subject.desc "grape api"
      subject.routes.should == []
    end
    it 'describes a method' do
      subject.desc "first method"
      subject.get :first do ; end
      subject.routes.length.should == 1
      route = subject.routes.first
      route.route_description.should == "first method"
      route.route_foo.should be_nil
      route.route_params.should == { }
    end
    it 'describes methods separately' do
      subject.desc "first method"
      subject.get :first do ; end
      subject.desc "second method"
      subject.get :second do ; end
      subject.routes.count.should == 2
      subject.routes.map { |route|
        { description: route.route_description, params: route.route_params }
      }.should eq [
        { description: "first method", params: {} },
        { description: "second method", params: {} }
    ]
    end
    it 'resets desc' do
      subject.desc "first method"
      subject.get :first do ; end
      subject.get :second do ; end
      subject.routes.map { |route|
        { description: route.route_description, params: route.route_params }
      }.should eq [
        { description: "first method", params: {} },
        { description: nil, params: {} }
    ]
    end
    it 'namespaces and describe arbitrary parameters' do
      subject.namespace 'ns' do
        desc "ns second", foo: "bar"
        get 'second' do ; end
      end
      subject.routes.map { |route|
        { description: route.route_description, foo: route.route_foo, params: route.route_params }
      }.should eq [
        { description: "ns second", foo: "bar", params: {} },
    ]
    end
    it 'includes details' do
      subject.desc "method", details: "method details"
      subject.get 'method' do ; end
      subject.routes.map { |route|
        { description: route.route_description, details: route.route_details, params: route.route_params }
      }.should eq [
        { description: "method", details: "method details", params: {} },
    ]
    end
    it 'describes a method with parameters' do
      subject.desc "Reverses a string.", { params:
        { "s" => { desc: "string to reverse", type: "string" } }
      }
      subject.get 'reverse' do
        params[:s].reverse
      end
      subject.routes.map { |route|
        { description: route.route_description, params: route.route_params }
      }.should eq [
        { description: "Reverses a string.", params: { "s" => { desc: "string to reverse", type: "string" } } }
    ]
    end
    it 'merges the parameters of the namespace with the parameters of the method' do
      subject.desc "namespace"
      subject.params do
        requires :ns_param, desc: "namespace parameter"
      end
      subject.namespace 'ns' do
        desc "method"
        params do
          optional :method_param, desc: "method parameter"
        end
        get 'method' do ; end
      end
      subject.routes.map { |route|
        { description: route.route_description, params: route.route_params }
      }.should eq [
        { description: "method",
          params: {
            "ns_param" => { required: true, desc: "namespace parameter" },
            "method_param" => { required: false, desc: "method parameter" }
          }
        }
    ]
    end
    it 'merges the parameters of nested namespaces' do
      subject.desc "ns1"
      subject.params do
        optional :ns_param, desc: "ns param 1"
        requires :ns1_param, desc: "ns1 param"
      end
      subject.namespace 'ns1' do
        desc "ns2"
        params do
          requires :ns_param, desc: "ns param 2"
          requires :ns2_param, desc: "ns2 param"
        end
        namespace 'ns2' do
          desc "method"
          params do
            optional :method_param, desc: "method param"
          end
          get 'method' do ; end
        end
      end
      subject.routes.map { |route|
        { description: route.route_description, params: route.route_params }
      }.should eq [
        { description: "method",
          params: {
            "ns_param" => { required: true, desc: "ns param 2" },
            "ns1_param" => { required: true, desc: "ns1 param" },
            "ns2_param" => { required: true, desc: "ns2 param" },
            "method_param" => { required: false, desc: "method param" }
          }
        }
    ]
    end
    it "groups nested params and prevents overwriting of params with same name in different groups" do
      subject.desc "method"
      subject.params do
        group :group1 do
          optional :param1, desc: "group1 param1 desc"
          requires :param2, desc: "group1 param2 desc"
        end
        group :group2 do
          optional :param1, desc: "group2 param1 desc"
          requires :param2, desc: "group2 param2 desc"
        end
      end
      subject.get "method" do ; end

      subject.routes.map { |route|
        route.route_params
      }.should eq [{
        "group1[param1]" => { required: false, desc: "group1 param1 desc" },
        "group1[param2]" => { required: true, desc: "group1 param2 desc" },
        "group2[param1]" => { required: false, desc: "group2 param1 desc" },
        "group2[param2]" => { required: true, desc: "group2 param2 desc" }
      }]
    end
    it 'uses full name of parameters in nested groups' do
      subject.desc "nesting"
      subject.params do
        requires :root_param, desc: "root param"
        group :nested do
          requires :nested_param, desc: "nested param"
        end
      end
      subject.get 'method' do ; end
      subject.routes.map { |route|
        { description: route.route_description, params: route.route_params }
      }.should eq [
        { description: "nesting",
          params: {
            "root_param" => { required: true, desc: "root param" },
            "nested[nested_param]" => { required: true, desc: "nested param" }
          }
        }
    ]
    end
    it 'parses parameters when no description is given' do
      subject.params do
        requires :one_param, desc: "one param"
      end
      subject.get 'method' do ; end
      subject.routes.map { |route|
        { description: route.route_description, params: route.route_params }
      }.should eq [
        { description: nil, params: { "one_param" => { required: true, desc: "one param" } } }
    ]
    end
    it 'does not symbolize params' do
      subject.desc "Reverses a string.", { params:
        { "s" => { desc: "string to reverse", type: "string" } }
      }
      subject.get 'reverse/:s' do
        params[:s].reverse
      end
      subject.routes.map { |route|
        { description: route.route_description, params: route.route_params }
      }.should eq [
        { description: "Reverses a string.", params: { "s" => { desc: "string to reverse", type: "string" } } }
    ]
    end
  end

  describe '.mount' do
    let(:mounted_app) { lambda { |env| [200, { }, ["MOUNTED"]] } }

    context 'with a bare rack app' do
      before do
        subject.mount mounted_app => '/mounty'
      end

      it 'makes a bare Rack app available at the endpoint' do
        get '/mounty'
        last_response.body.should == 'MOUNTED'
      end

      it 'anchors the routes, passing all subroutes to it' do
        get '/mounty/awesome'
        last_response.body.should == 'MOUNTED'
      end

      it 'is able to cascade' do
        subject.mount lambda { |env|
          headers = {}
          headers['X-Cascade'] == 'pass' unless env['PATH_INFO'].include?('boo')
          [200, headers, ["Farfegnugen"]]
        } => '/'

        get '/boo'
        last_response.body.should == 'Farfegnugen'
        get '/mounty'
        last_response.body.should == 'MOUNTED'
      end
    end

    context 'without a hash' do
      it 'calls through setting the route to "/"' do
        subject.mount mounted_app
        get '/'
        last_response.body.should == 'MOUNTED'
      end
    end

    context 'mounting an API' do
      it 'applies the settings of the mounting api' do
        subject.version 'v1', using: :path

        subject.namespace :cool do
          app = Class.new(Grape::API)
          app.get('/awesome') do
            "yo"
          end

          mount app
        end

        get '/v1/cool/awesome'
        last_response.body.should == 'yo'
      end

      it 'applies the settings to nested mounted apis' do
        subject.version 'v1', using: :path

        subject.namespace :cool do
          inner_app = Class.new(Grape::API)
          inner_app.get('/awesome') do
            "yo"
          end

          app = Class.new(Grape::API)
          app.mount inner_app
          mount app
        end

        get '/v1/cool/awesome'
        last_response.body.should == 'yo'
      end

      it 'inherits rescues even when some defined by mounted' do
        subject.rescue_from :all do |e|
          rack_response("rescued from #{e.message}", 202)
        end
        subject.namespace :mounted do
          app = Class.new(Grape::API)
          app.rescue_from ArgumentError
          app.get('/fail') { raise "doh!" }
          mount app
        end
        get '/mounted/fail'
        last_response.status.should eql 202
        last_response.body.should == 'rescued from doh!'
      end

      it 'collects the routes of the mounted api' do
        subject.namespace :cool do
          app = Class.new(Grape::API)
          app.get('/awesome') { }
          app.post('/sauce') { }
          mount app
        end
        subject.routes.size.should == 2
        subject.routes.first.route_path.should =~ %r{\/cool\/awesome}
        subject.routes.last.route_path.should =~ %r{\/cool\/sauce}
      end

      it 'mounts on a path' do
        subject.namespace :cool do
          app = Class.new(Grape::API)
          app.get '/awesome' do
            "sauce"
          end
          mount app => '/mounted'
        end
        get "/mounted/cool/awesome"
        last_response.status.should == 200
        last_response.body.should == "sauce"
      end

      it 'mounts on a nested path' do
        app1 = Class.new(Grape::API)
        app2 = Class.new(Grape::API)
        app2.get '/nice' do
          "play"
        end
        # note that the reverse won't work, mount from outside-in
        subject.mount app1 => '/app1'
        app1.mount app2 => '/app2'
        get "/app1/app2/nice"
        last_response.status.should == 200
        last_response.body.should == "play"
      end

    end
  end

  describe '.endpoints' do
    it 'adds one for each route created' do
      subject.get '/'
      subject.post '/'
      subject.endpoints.size.should == 2
    end
  end

  describe '.compile' do
    it 'sets the instance' do
      subject.instance.should be_nil
      subject.compile
      subject.instance.should be_kind_of(subject)
    end
  end

  describe '.change!' do
    it 'invalidates any compiled instance' do
      subject.compile
      subject.change!
      subject.instance.should be_nil
    end
  end

  describe ".endpoint" do
    before(:each) do
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
      options = MultiJson.load(last_response.body)
      options["path"].should == ["/endpoint/options"]
      options["source_location"][0].should include "api_spec.rb"
      options["source_location"][1].to_i.should > 0
    end
  end

  describe '.route' do
    context 'plain' do
      before(:each) do
        subject.get '/' do
          route.route_path
        end
        subject.get '/path' do
          route.route_path
        end
      end
      it 'provides access to route info' do
        get '/'
        last_response.body.should == "/(.:format)"
        get '/path'
        last_response.body.should == "/path(.:format)"
      end
    end
    context 'with desc' do
      before(:each) do
        subject.desc 'returns description'
        subject.get '/description' do
          route.route_description
        end
        subject.desc 'returns parameters', { params: { "x" => "y" } }
        subject.get '/params/:id' do
          route.route_params[params[:id]]
        end
      end
      it 'returns route description' do
        get '/description'
        last_response.body.should == "returns description"
      end
      it 'returns route parameters' do
        get '/params/x'
        last_response.body.should == "y"
      end
    end
  end
  describe '.format' do
    context ':txt' do
      before(:each) do
        subject.format :txt
        subject.content_type :json, "application/json"
        subject.get '/meaning_of_life' do
          { meaning_of_life: 42 }
        end
      end
      it 'forces txt without an extension' do
        get '/meaning_of_life'
        last_response.body.should == { meaning_of_life: 42 }.to_s
      end
      it 'does not force txt with an extension' do
        get '/meaning_of_life.json'
        last_response.body.should == { meaning_of_life: 42 }.to_json
      end
      it 'forces txt from a non-accepting header' do
        get '/meaning_of_life', {}, { 'HTTP_ACCEPT' => 'application/json' }
        last_response.body.should == { meaning_of_life: 42 }.to_s
      end
    end
    context ':txt only' do
      before(:each) do
        subject.format :txt
        subject.get '/meaning_of_life' do
          { meaning_of_life: 42 }
        end
      end
      it 'forces txt without an extension' do
        get '/meaning_of_life'
        last_response.body.should == { meaning_of_life: 42 }.to_s
      end
      it 'forces txt with the wrong extension' do
        get '/meaning_of_life.json'
        last_response.body.should == { meaning_of_life: 42 }.to_s
      end
      it 'forces txt from a non-accepting header' do
        get '/meaning_of_life', {}, { 'HTTP_ACCEPT' => 'application/json' }
        last_response.body.should == { meaning_of_life: 42 }.to_s
      end
    end
    context ':json' do
      before(:each) do
        subject.format :json
        subject.content_type :txt, "text/plain"
        subject.get '/meaning_of_life' do
          { meaning_of_life: 42 }
        end
      end
      it 'forces json without an extension' do
        get '/meaning_of_life'
        last_response.body.should == { meaning_of_life: 42 }.to_json
      end
      it 'does not force json with an extension' do
        get '/meaning_of_life.txt'
        last_response.body.should == { meaning_of_life: 42 }.to_s
      end
      it 'forces json from a non-accepting header' do
        get '/meaning_of_life', {}, { 'HTTP_ACCEPT' => 'text/html' }
        last_response.body.should == { meaning_of_life: 42 }.to_json
      end
      it 'can be overwritten with an explicit content type' do
        subject.get '/meaning_of_life_with_content_type' do
          content_type "text/plain"
          { meaning_of_life: 42 }.to_s
        end
        get '/meaning_of_life_with_content_type'
        last_response.body.should == { meaning_of_life: 42 }.to_s
      end
      it 'raised :error from middleware' do
        middleware = Class.new(Grape::Middleware::Base) do
          def before
            throw :error, message: "Unauthorized", status: 42
          end
        end
        subject.use middleware
        subject.get do

        end
        get "/"
        last_response.status.should == 42
        last_response.body.should == { error: "Unauthorized" }.to_json
      end

    end
    context ':serializable_hash' do
      before(:each) do
        class SerializableHashExample
          def serializable_hash
            { abc: 'def' }
          end
        end
        subject.format :serializable_hash
      end
      it 'instance' do
        subject.get '/example' do
          SerializableHashExample.new
        end
        get '/example'
        last_response.body.should == '{"abc":"def"}'
      end
      it 'root' do
        subject.get '/example' do
          { "root" => SerializableHashExample.new }
        end
        get '/example'
        last_response.body.should == '{"root":{"abc":"def"}}'
      end
      it 'array' do
        subject.get '/examples' do
          [SerializableHashExample.new, SerializableHashExample.new]
        end
        get '/examples'
        last_response.body.should == '[{"abc":"def"},{"abc":"def"}]'
      end
    end
    context ":xml" do
      before(:each) do
        subject.format :xml
      end
      it 'string' do
        subject.get "/example" do
          "example"
        end
        get '/example'
        last_response.status.should == 500
        last_response.body.should == <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<error>
  <message>cannot convert String to xml</message>
</error>
XML
      end
      it 'hash' do
        subject.get "/example" do
          ActiveSupport::OrderedHash[
            :example1, "example1",
            :example2, "example2"
        ]
        end
        get '/example'
        last_response.status.should == 200
        last_response.body.should == <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<hash>
  <example1>example1</example1>
  <example2>example2</example2>
</hash>
XML
      end
      it 'array' do
        subject.get "/example" do
          ["example1", "example2"]
        end
        get '/example'
        last_response.status.should == 200
        last_response.body.should == <<-XML
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
            throw :error, message: "Unauthorized", status: 42
          end
        end
        subject.use middleware
        subject.get do

        end
        get "/"
        last_response.status.should == 42
        last_response.body.should == <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<error>
  <message>Unauthorized</message>
</error>
XML
      end
    end
  end

  context "catch-all" do
    before do
      api1 = Class.new(Grape::API)
      api1.version 'v1', using: :path
      api1.get "hello" do
        "v1"
      end
      api2 = Class.new(Grape::API)
      api2.version 'v2', using: :path
      api2.get "hello" do
        "v2"
      end
      subject.mount api1
      subject.mount api2
    end
    [true, false].each do |anchor|
      it "anchor=#{anchor}" do
        subject.route :any, '*path', anchor: anchor do
          error!("Unrecognized request path: #{params[:path] } - #{env['PATH_INFO'] }#{env['SCRIPT_NAME'] }", 404)
        end
        get "/v1/hello"
        last_response.status.should == 200
        last_response.body.should == "v1"
        get "/v2/hello"
        last_response.status.should == 200
        last_response.body.should == "v2"
        get "/foobar"
        last_response.status.should == 404
        last_response.body.should == "Unrecognized request path: foobar - /foobar"
      end
    end
  end

  context "cascading" do
    context "via version" do
      it "cascades" do
        subject.version 'v1', using: :path, cascade: true
        get "/v1/hello"
        last_response.status.should == 404
        last_response.headers["X-Cascade"].should == "pass"
      end
      it "does not cascade" do
        subject.version 'v2', using: :path, cascade: false
        get "/v2/hello"
        last_response.status.should == 404
        last_response.headers.keys.should_not include "X-Cascade"
      end
    end
    context "via endpoint" do
      it "cascades" do
        subject.cascade true
        get "/hello"
        last_response.status.should == 404
        last_response.headers["X-Cascade"].should == "pass"
      end
      it "does not cascade" do
        subject.cascade false
        get "/hello"
        last_response.status.should == 404
        last_response.headers.keys.should_not include "X-Cascade"
      end
    end
  end

  context 'with json default_error_formatter' do
    it 'returns json error' do
      subject.content_type :json, "application/json"
      subject.default_error_formatter :json
      subject.get '/something' do
        'foo'
      end
      get '/something'
      last_response.status.should == 406
      last_response.body.should == "{\"error\":\"The requested format 'txt' is not supported.\"}"
    end
  end
end
