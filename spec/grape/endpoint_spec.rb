require 'spec_helper'

describe Grape::Endpoint do
  subject { Class.new(Grape::API) }
  def app; subject end

  describe '#initialize' do
    it 'should take a settings stack, options, and a block' do
      expect{ Grape::Endpoint.new(Grape::Util::HashStack.new, {
        :path => '/',
        :method => :get
      }, &Proc.new{}) }.not_to raise_error
    end
  end

  it 'should set itself in the env upon call' do
    subject.get('/'){ "Hello world." }
    get '/'
    last_request.env['api.endpoint'].should be_kind_of(Grape::Endpoint)
  end

  describe '#status' do
    it 'should be callable from within a block' do
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
    it 'should be callable from within a block' do
      subject.get('/hey') do
        header 'X-Awesome', 'true'
        "Awesome"
      end

      get '/hey'
      last_response.headers['X-Awesome'].should == 'true'
    end
  end

  describe '#cookies' do
    it 'should be callable from within a block' do
      subject.get('/get/cookies') do
        cookies['my-awesome-cookie1'] = 'is cool'
        cookies['my-awesome-cookie2'] = {
            :value => 'is cool too',
            :domain => 'my.example.com',
            :path => '/',
            :secure => true,
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

    it "should set browser cookies and should not set response cookies" do
      subject.get('/username') do
        cookies[:username]
      end
      get('/username', {}, 'HTTP_COOKIE' => 'username=mrplum; sandbox=true')

      last_response.body.should == 'mrplum'
      last_response.headers['Set-Cookie'].should_not =~ /username=mrplum/
      last_response.headers['Set-Cookie'].should_not =~ /sandbox=true/
    end

    it "should set and update browser cookies" do
      subject.get('/username') do
        cookies[:sandbox] = true if cookies[:sandbox] == 'false'
        cookies[:username] += "_test"
      end
      get('/username', {}, 'HTTP_COOKIE' => 'username=user; sandbox=false')
      last_response.body.should == 'user_test'
      last_response.headers['Set-Cookie'].should =~ /username=user_test/
      last_response.headers['Set-Cookie'].should =~ /sandbox=true/
    end

    it "should delete cookie" do
      subject.get('/test') do
        sum = 0
        cookies.each do |name, val|
          sum += val.to_i
          cookies.delete name
        end
        sum
      end
      get('/test', {}, 'HTTP_COOKIE' => 'delete_this_cookie=1; and_this=2')
      last_response.body.should == '3'
      last_response.headers['Set-Cookie'].split("\n").sort.should == [
          "and_this=deleted; expires=Thu, 01-Jan-1970 00:00:00 GMT",
          "delete_this_cookie=deleted; expires=Thu, 01-Jan-1970 00:00:00 GMT"
      ]
    end
  end

  describe '#params' do
    it 'should be available to the caller' do
      subject.get('/hey') do
        params[:howdy]
      end

      get '/hey?howdy=hey'
      last_response.body.should == 'hey'
    end

    it 'should parse from path segments' do
      subject.get('/hey/:id') do
        params[:id]
      end

      get '/hey/12'
      last_response.body.should == '12'
    end

    it 'should deeply convert nested params' do
      subject.get '/location' do
        params[:location][:city]
      end
      get '/location?location[city]=Dallas'
      last_response.body.should == 'Dallas'
    end

    context 'with special requirements' do
      it 'should parse email param with provided requirements for params' do
        subject.get('/:person_email', :requirements => { :person_email => /.*/ }) do
        params[:person_email]
        end

        get '/rodzyn@grape.com'
        last_response.body.should == 'rodzyn@grape.com'

        get 'rodzyn@grape.com.pl'
        last_response.body.should == 'rodzyn@grape.com.pl'
      end

      it 'should parse many params with provided regexps' do
        subject.get('/:person_email/test/:number',
          :requirements => {
            :person_email => /rodzyn@(.*).com/,
            :number => /[0-9]/ }) do
        params[:person_email] << params[:number]
        end

        get '/rodzyn@grape.com/test/1'
        last_response.body.should == 'rodzyn@grape.com1'

        get '/rodzyn@testing.wrong/test/1'
        last_response.status.should == 404

        get 'rodzyn@test.com/test/wrong_number'
        last_response.status.should == 404

        get 'rodzyn@test.com/wrong_middle/1'
        last_response.status.should == 404
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

      it 'should convert JSON bodies to params' do
        post '/request_body', MultiJson.encode(user: 'Bobby T.'), {'CONTENT_TYPE' => 'application/json'}
        last_response.body.should == 'Bobby T.'
      end

      it 'should convert JSON bodies to params' do
        put '/request_body', MultiJson.encode(user: 'Bobby T.'), {'CONTENT_TYPE' => 'application/json'}
        last_response.body.should == 'Bobby T.'
      end

      it 'should convert XML bodies to params' do
        post '/request_body', '<user>Bobby T.</user>', {'CONTENT_TYPE' => 'application/xml'}
        last_response.body.should == 'Bobby T.'
      end

      it 'should convert XML bodies to params' do
        put '/request_body', '<user>Bobby T.</user>', {'CONTENT_TYPE' => 'application/xml'}
        last_response.body.should == 'Bobby T.'
      end

      it 'does not include parameters not defined by the body' do
        subject.post '/omitted_params' do
          body_params[:version].should == nil
        end
        post '/omitted_params', MultiJson.encode(user: 'Blah'), {'CONTENT_TYPE' => 'application/json'}
      end
    end
  end

  describe '#error!' do
    it 'should accept a message' do
      subject.get('/hey') do
        error! "This is not valid."
        "This is valid."
      end

      get '/hey'
      last_response.status.should == 403
      last_response.body.should == "This is not valid."
    end

    it 'should accept a code' do
      subject.get('/hey') do
        error! "Unauthorized.", 401
      end

      get '/hey'
      last_response.status.should == 401
      last_response.body.should == "Unauthorized."
    end

    it 'should accept an object and render it in format' do
      subject.get '/hey' do
        error!({'dude' => 'rad'}, 403)
      end

      get '/hey.json'
      last_response.status.should == 403
      last_response.body.should == '{"dude":"rad"}'
    end
  end
  
  describe "#redirect" do 
    it "should redirect to a url with status 302" do 
      subject.get('/hey') do 
        redirect "/ha"
      end
      get '/hey'
      last_response.status.should eq 302
      last_response.headers['Location'].should eq "/ha"
      last_response.body.should eq ""
    end

    it "should have status code 303 if it is not get request and it is http 1.1" do
      subject.post('/hey') do 
        redirect "/ha"
      end
      post '/hey', {}, 'HTTP_VERSION' => 'HTTP/1.1'
      last_response.status.should eq 303
      last_response.headers['Location'].should eq "/ha"
    end

    it "support permanent redirect" do 
      subject.get('/hey') do 
        redirect "/ha", :permanent => true
      end
      get '/hey'
      last_response.status.should eq 304
      last_response.headers['Location'].should eq "/ha"
      last_response.body.should eq ""
    end
  end

  it 'should not persist params between calls' do
    subject.post('/new') do
      params[:text]
    end

    post '/new', :text => 'abc'
    last_response.body.should == 'abc'

    post '/new', :text => 'def'
    last_response.body.should == 'def'
  end

  it 'should reset all instance variables (except block) between calls' do
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

  describe '#present' do
    it 'should just set the object as the body if no options are provided' do
      subject.get '/example' do
        present({:abc => 'def'})
        body.should == {:abc => 'def'}
      end
      get '/example'
    end

    it 'should call through to the provided entity class if one is given' do
      subject.get '/example' do
        entity_mock = Object.new
        entity_mock.should_receive(:represent)
        present Object.new, :with => entity_mock
      end
      get '/example'
    end

    it 'should pull a representation from the class options if it exists' do
      entity = Class.new(Grape::Entity)
      entity.stub!(:represent).and_return("Hiya")

      subject.represent Object, :with => entity
      subject.get '/example' do
        present Object.new
      end
      get '/example'
      last_response.body.should == 'Hiya'
    end

    it 'should pull a representation from the class ancestor if it exists' do
      entity = Class.new(Grape::Entity)
      entity.stub!(:represent).and_return("Hiya")

      subclass = Class.new(Object)

      subject.represent Object, :with => entity
      subject.get '/example' do
        present subclass.new
      end
      get '/example'
      last_response.body.should == 'Hiya'
    end

    it 'should add a root key to the output if one is given' do
      subject.get '/example' do
        present({:abc => 'def'}, :root => :root)
        body.should == {:root => {:abc => 'def'}}
      end
      get '/example'
    end
  end

  context 'filters' do
    describe 'before filters' do
      it 'should run the before filter if set' do
        subject.before{ env['before_test'] = "OK" }
        subject.get('/before_test'){ env['before_test'] }

        get '/before_test'
        last_response.body.should == "OK"
      end
    end

    describe 'after filters' do
      it 'should override the response body if it sets it' do
        subject.after{ body "after" }
        subject.get('/after_test'){ "during" }
        get '/after_test'
        last_response.body.should == 'after'
      end

      it 'should not override the response body with its return' do
        subject.after{ "after" }
        subject.get('/after_test'){ "body" }
        get '/after_test'
        last_response.body.should == "body"
      end
    end
  end

  context 'anchoring' do
    verbs = %w(post get head delete put options patch)

    verbs.each do |verb|
      it "should allow for the anchoring option with a #{verb.upcase} method" do
        subject.send(verb, '/example', :anchor => true) do
          verb
        end
        send(verb, '/example/and/some/more')
        last_response.status.should eql 404
      end

      it "should anchor paths by default for the #{verb.upcase} method" do
        subject.send(verb, '/example') do
          verb
        end
        send(verb, '/example/and/some/more')
        last_response.status.should eql 404
      end

      it "should respond to /example/and/some/more for the non-anchored #{verb.upcase} method" do
        subject.send(verb, '/example', :anchor => false) do
          verb
        end
        send(verb, '/example/and/some/more')
        last_response.status.should eql (verb == "post" ? 201 : 200)
        last_response.body.should eql verb
      end
    end
  end
end
