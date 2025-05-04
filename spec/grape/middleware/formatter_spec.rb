# frozen_string_literal: true

describe Grape::Middleware::Formatter do
  subject { described_class.new(app) }

  before { allow(subject).to receive(:dup).and_return(subject) }

  let(:body) { { 'foo' => 'bar' } }
  let(:app) { ->(_env) { [200, {}, [body]] } }

  context 'serialization' do
    let(:body) { { 'abc' => 'def' } }
    let(:env) do
      { Rack::PATH_INFO => '/somewhere', 'HTTP_ACCEPT' => 'application/json' }
    end

    it 'looks at the bodies for possibly serializable data' do
      r = Rack::MockResponse[*subject.call(env)]
      expect(r.body).to eq(Grape::Json.dump(body))
    end

    context 'default format' do
      let(:body) { ['foo'] }
      let(:env) do
        { Rack::PATH_INFO => '/somewhere', 'HTTP_ACCEPT' => 'application/json' }
      end

      it 'calls #to_json since default format is json' do
        body.instance_eval do
          def to_json(*_args)
            '"bar"'
          end
        end
        r = Rack::MockResponse[*subject.call(env)]
        expect(r.body).to eq('"bar"')
      end
    end

    context 'xml' do
      let(:body) { +'string' }
      let(:env) do
        { Rack::PATH_INFO => '/somewhere.xml', 'HTTP_ACCEPT' => 'application/json' }
      end

      it 'calls #to_xml if the content type is xml' do
        body.instance_eval do
          def to_xml
            '<bar/>'
          end
        end
        r = Rack::MockResponse[*subject.call(env)]
        expect(r.body).to eq('<bar/>')
      end
    end
  end

  context 'error handling' do
    let(:formatter) { double(:formatter) }
    let(:env) do
      { Rack::PATH_INFO => '/somewhere.xml', 'HTTP_ACCEPT' => 'application/json' }
    end

    before do
      allow(Grape::Formatter).to receive(:formatter_for) { formatter }
    end

    it 'rescues formatter-specific exceptions' do
      allow(formatter).to receive(:call) { raise Grape::Exceptions::InvalidFormatter.new(String, 'xml') }

      expect do
        catch(:error) { subject.call(env) }
      end.not_to raise_error
    end

    it 'does not rescue other exceptions' do
      allow(formatter).to receive(:call) { raise StandardError }

      expect do
        catch(:error) { subject.call(Rack::PATH_INFO => '/somewhere.xml', 'HTTP_ACCEPT' => 'application/json') }
      end.to raise_error(StandardError)
    end
  end

  context 'detection' do
    context 'when path contains invalid byte sequence' do
      it 'does not raise an exception' do
        expect { subject.call(Rack::PATH_INFO => "/info.\x80") }.not_to raise_error
      end
    end

    it 'uses the xml extension if one is provided' do
      subject.call(Rack::PATH_INFO => '/info.xml')
      expect(subject.env[Grape::Env::API_FORMAT]).to eq(:xml)
    end

    it 'uses the json extension if one is provided' do
      subject.call(Rack::PATH_INFO => '/info.json')
      expect(subject.env[Grape::Env::API_FORMAT]).to eq(:json)
    end

    it 'uses the format parameter if one is provided' do
      subject.call(Rack::PATH_INFO => '/info', Rack::QUERY_STRING => 'format=json')
      expect(subject.env[Grape::Env::API_FORMAT]).to eq(:json)
    end

    it 'uses the default format if none is provided' do
      subject.call(Rack::PATH_INFO => '/info')
      expect(subject.env[Grape::Env::API_FORMAT]).to eq(:txt)
    end

    it 'uses the requested format if provided in headers' do
      subject.call(Rack::PATH_INFO => '/info', 'HTTP_ACCEPT' => 'application/json')
      expect(subject.env[Grape::Env::API_FORMAT]).to eq(:json)
    end

    it 'uses the file extension format if provided before headers' do
      subject.call(Rack::PATH_INFO => '/info.txt', 'HTTP_ACCEPT' => 'application/json')
      expect(subject.env[Grape::Env::API_FORMAT]).to eq(:txt)
    end
  end

  context 'accept header detection' do
    context 'when header contains invalid byte sequence' do
      it 'does not raise an exception' do
        expect { subject.call(Rack::PATH_INFO => '/info', 'HTTP_ACCEPT' => "Hello \x80") }.not_to raise_error
      end
    end

    it 'detects from the Accept header' do
      subject.call(Rack::PATH_INFO => '/info', 'HTTP_ACCEPT' => 'application/xml')
      expect(subject.env[Grape::Env::API_FORMAT]).to eq(:xml)
    end

    it 'uses quality rankings to determine formats' do
      subject.call(Rack::PATH_INFO => '/info', 'HTTP_ACCEPT' => 'application/json; q=0.3,application/xml; q=1.0')
      expect(subject.env[Grape::Env::API_FORMAT]).to eq(:xml)

      subject.call(Rack::PATH_INFO => '/info', 'HTTP_ACCEPT' => 'application/json; q=1.0,application/xml; q=0.3')
      expect(subject.env[Grape::Env::API_FORMAT]).to eq(:json)
    end

    it 'handles quality rankings mixed with nothing' do
      subject.call(Rack::PATH_INFO => '/info', 'HTTP_ACCEPT' => 'application/json,application/xml; q=1.0')
      expect(subject.env[Grape::Env::API_FORMAT]).to eq(:xml)

      subject.call(Rack::PATH_INFO => '/info', 'HTTP_ACCEPT' => 'application/xml; q=1.0,application/json')
      expect(subject.env[Grape::Env::API_FORMAT]).to eq(:json)
    end

    it 'handles quality rankings that have a default 1.0 value' do
      subject.call(Rack::PATH_INFO => '/info', 'HTTP_ACCEPT' => 'application/json,application/xml;q=0.5')
      expect(subject.env[Grape::Env::API_FORMAT]).to eq(:json)
      subject.call(Rack::PATH_INFO => '/info', 'HTTP_ACCEPT' => 'application/xml;q=0.5,application/json')
      expect(subject.env[Grape::Env::API_FORMAT]).to eq(:json)
    end

    it 'parses headers with other attributes' do
      subject.call(Rack::PATH_INFO => '/info', 'HTTP_ACCEPT' => 'application/json; abc=2.3; q=1.0,application/xml; q=0.7')
      expect(subject.env[Grape::Env::API_FORMAT]).to eq(:json)
    end

    it 'ensures that a quality of 0 is less preferred than any other content type' do
      subject.call(Rack::PATH_INFO => '/info', 'HTTP_ACCEPT' => 'application/json;q=0.0,application/xml')
      expect(subject.env[Grape::Env::API_FORMAT]).to eq(:xml)
      subject.call(Rack::PATH_INFO => '/info', 'HTTP_ACCEPT' => 'application/xml,application/json;q=0.0')
      expect(subject.env[Grape::Env::API_FORMAT]).to eq(:xml)
    end

    context 'with custom vendored content types' do
      context 'when registered' do
        subject { described_class.new(app, content_types: { custom: 'application/vnd.test+json' }) }

        it 'uses the custom type' do
          subject.call(Rack::PATH_INFO => '/info', 'HTTP_ACCEPT' => 'application/vnd.test+json')
          expect(subject.env[Grape::Env::API_FORMAT]).to eq(:custom)
        end
      end

      context 'when unregistered' do
        it 'returns the default content type text/plain' do
          r = Rack::MockResponse[*subject.call(Rack::PATH_INFO => '/info', 'HTTP_ACCEPT' => 'application/vnd.test+json')]
          expect(r.headers[Rack::CONTENT_TYPE]).to eq('text/plain')
        end
      end
    end

    it 'parses headers with symbols as hash keys' do
      subject.call(Rack::PATH_INFO => '/info', 'HTTP_ACCEPT' => 'application/xml', system_time: '091293')
      expect(subject.env[:system_time]).to eq('091293')
    end
  end

  context 'content-type' do
    it 'is set for json' do
      _, headers, = subject.call(Rack::PATH_INFO => '/info.json')
      expect(headers[Rack::CONTENT_TYPE]).to eq('application/json')
    end

    it 'is set for xml' do
      _, headers, = subject.call(Rack::PATH_INFO => '/info.xml')
      expect(headers[Rack::CONTENT_TYPE]).to eq('application/xml')
    end

    it 'is set for txt' do
      _, headers, = subject.call(Rack::PATH_INFO => '/info.txt')
      expect(headers[Rack::CONTENT_TYPE]).to eq('text/plain')
    end

    it 'is set for custom' do
      s = described_class.new(app, content_types: { custom: 'application/x-custom' })
      _, headers, = s.call(Rack::PATH_INFO => '/info.custom')
      expect(headers[Rack::CONTENT_TYPE]).to eq('application/x-custom')
    end

    it 'is set for vendored with registered type' do
      s = described_class.new(app, content_types: { custom: 'application/vnd.test+json' })
      _, headers, = s.call(Rack::PATH_INFO => '/info', 'HTTP_ACCEPT' => 'application/vnd.test+json')
      expect(headers[Rack::CONTENT_TYPE]).to eq('application/vnd.test+json')
    end
  end

  context 'format' do
    it 'uses custom formatter' do
      s = described_class.new(app, content_types: { custom: "don't care" }, formatters: { custom: ->(_obj, _env) { 'CUSTOM FORMAT' } })
      r = Rack::MockResponse[*s.call(Rack::PATH_INFO => '/info.custom')]
      expect(r.body).to eq('CUSTOM FORMAT')
    end

    context 'default' do
      let(:body) { ['blah'] }

      it 'uses default json formatter' do
        r = Rack::MockResponse[*subject.call(Rack::PATH_INFO => '/info.json')]
        expect(r.body).to eq(Grape::Json.dump(body))
      end
    end

    it 'uses custom json formatter' do
      subject.options[:formatters] = { json: ->(_obj, _env) { 'CUSTOM JSON FORMAT' } }
      r = Rack::MockResponse[*subject.call(Rack::PATH_INFO => '/info.json')]
      expect(r.body).to eq('CUSTOM JSON FORMAT')
    end
  end

  context 'no content responses' do
    let(:no_content_response) { ->(status) { [status, {}, []] } }

    statuses_without_body = if Gem::Version.new(Rack.release) >= Gem::Version.new('2.1.0')
                              Rack::Utils::STATUS_WITH_NO_ENTITY_BODY.keys
                            else
                              Rack::Utils::STATUS_WITH_NO_ENTITY_BODY
                            end

    statuses_without_body.each do |status|
      it "does not modify a #{status} response" do
        expected_response = no_content_response[status]
        allow(app).to receive(:call).and_return(expected_response)
        expect(subject.call({})).to eq(expected_response)
      end
    end
  end

  context 'input' do
    content_types = ['application/json', 'application/json; charset=utf-8'].freeze
    %w[POST PATCH PUT DELETE].each do |method|
      context 'when body is not nil or empty' do
        context 'when Content-Type is supported' do
          let(:io) { StringIO.new('{"is_boolean":true,"string":"thing"}') }
          let(:content_type) { 'application/json' }

          it "parses the body from #{method} and copies values into rack.request.form_hash" do
            subject.call(
              Rack::PATH_INFO => '/info',
              Rack::REQUEST_METHOD => method,
              'CONTENT_TYPE' => content_type,
              Rack::RACK_INPUT => io,
              'CONTENT_LENGTH' => io.length.to_s
            )
            expect(subject.env[Rack::RACK_REQUEST_FORM_HASH]['is_boolean']).to be true
            expect(subject.env[Rack::RACK_REQUEST_FORM_HASH]['string']).to eq('thing')
          end
        end

        context 'when Content-Type is not supported' do
          let(:io) { StringIO.new('{"is_boolean":true,"string":"thing"}') }
          let(:content_type) { 'application/atom+xml' }

          it 'returns a 415 HTTP error status' do
            error = catch(:error) do
              subject.call(
                Rack::PATH_INFO => '/info',
                Rack::REQUEST_METHOD => method,
                'CONTENT_TYPE' => content_type,
                Rack::RACK_INPUT => io,
                'CONTENT_LENGTH' => io.length.to_s
              )
            end
            expect(error[:status]).to eq(415)
            expect(error[:message]).to eq("The provided content-type 'application/atom+xml' is not supported.")
          end
        end
      end

      context 'when body is nil' do
        let(:io) { double }

        before do
          allow(io).to receive_message_chain(rewind: nil, read: nil)
        end

        it 'does not read and parse the body' do
          expect(subject).not_to receive(:read_rack_input)
          subject.call(
            Rack::PATH_INFO => '/info',
            Rack::REQUEST_METHOD => method,
            'CONTENT_TYPE' => 'application/json',
            Rack::RACK_INPUT => io,
            'CONTENT_LENGTH' => '0'
          )
        end
      end

      context 'when body is empty' do
        let(:io) { double }

        before do
          allow(io).to receive_messages(rewind: nil, read: '')
        end

        it 'does not read and parse the body' do
          expect(subject).not_to receive(:read_rack_input)
          subject.call(
            Rack::PATH_INFO => '/info',
            Rack::REQUEST_METHOD => method,
            'CONTENT_TYPE' => 'application/json',
            Rack::RACK_INPUT => io,
            'CONTENT_LENGTH' => 0
          )
        end
      end

      content_types.each do |content_type|
        context content_type do
          it "parses the body from #{method} and copies values into rack.request.form_hash" do
            io = StringIO.new('{"is_boolean":true,"string":"thing"}')
            subject.call(
              Rack::PATH_INFO => '/info',
              Rack::REQUEST_METHOD => method,
              'CONTENT_TYPE' => content_type,
              Rack::RACK_INPUT => io,
              'CONTENT_LENGTH' => io.length.to_s
            )
            expect(subject.env[Rack::RACK_REQUEST_FORM_HASH]['is_boolean']).to be true
            expect(subject.env[Rack::RACK_REQUEST_FORM_HASH]['string']).to eq('thing')
          end
        end
      end
      it "parses the chunked body from #{method} and copies values into rack.request.from_hash" do
        io = StringIO.new('{"is_boolean":true,"string":"thing"}')
        subject.call(
          Rack::PATH_INFO => '/infol',
          Rack::REQUEST_METHOD => method,
          'CONTENT_TYPE' => 'application/json',
          Rack::RACK_INPUT => io,
          'HTTP_TRANSFER_ENCODING' => 'chunked'
        )
        expect(subject.env[Rack::RACK_REQUEST_FORM_HASH]['is_boolean']).to be true
        expect(subject.env[Rack::RACK_REQUEST_FORM_HASH]['string']).to eq('thing')
      end

      it 'rewinds IO' do
        io = StringIO.new('{"is_boolean":true,"string":"thing"}')
        io.read
        subject.call(
          Rack::PATH_INFO => '/infol',
          Rack::REQUEST_METHOD => method,
          'CONTENT_TYPE' => 'application/json',
          Rack::RACK_INPUT => io,
          'HTTP_TRANSFER_ENCODING' => 'chunked'
        )
        expect(subject.env[Rack::RACK_REQUEST_FORM_HASH]['is_boolean']).to be true
        expect(subject.env[Rack::RACK_REQUEST_FORM_HASH]['string']).to eq('thing')
      end

      it "parses the body from an xml #{method} and copies values into rack.request.from_hash" do
        io = StringIO.new('<thing><name>Test</name></thing>')
        subject.call(
          Rack::PATH_INFO => '/info.xml',
          Rack::REQUEST_METHOD => method,
          'CONTENT_TYPE' => 'application/xml',
          Rack::RACK_INPUT => io,
          'CONTENT_LENGTH' => io.length.to_s
        )
        if Object.const_defined? :MultiXml
          expect(subject.env[Rack::RACK_REQUEST_FORM_HASH]['thing']['name']).to eq('Test')
        else
          expect(subject.env[Rack::RACK_REQUEST_FORM_HASH]['thing']['name']['__content__']).to eq('Test')
        end
      end

      [Rack::Request::FORM_DATA_MEDIA_TYPES, Rack::Request::PARSEABLE_DATA_MEDIA_TYPES].flatten.each do |content_type|
        it "ignores #{content_type}" do
          io = StringIO.new('name=Other+Test+Thing')
          subject.call(
            Rack::PATH_INFO => '/info',
            Rack::REQUEST_METHOD => method,
            'CONTENT_TYPE' => content_type,
            Rack::RACK_INPUT => io,
            'CONTENT_LENGTH' => io.length.to_s
          )
          expect(subject.env[Rack::RACK_REQUEST_FORM_HASH]).to be_nil
        end
      end
    end
  end

  context 'send file' do
    let(:file) { double(File) }
    let(:file_body) { Grape::ServeStream::StreamResponse.new(file) }
    let(:app) { ->(_env) { [200, {}, file_body] } }
    let(:body) { 'data' }
    let(:env) do
      { Rack::PATH_INFO => '/somewhere', 'HTTP_ACCEPT' => 'application/json' }
    end
    let(:headers) do
      if Gem::Version.new(Rack.release) < Gem::Version.new('3.1')
        { Rack::CONTENT_TYPE => 'application/json', Rack::CONTENT_LENGTH => body.bytesize.to_s }
      else
        { Rack::CONTENT_TYPE => 'application/json' }
      end
    end

    it 'returns a file response' do
      expect(file).to receive(:each).and_yield(body)
      r = Rack::MockResponse[*subject.call(env)]
      expect(r).to be_successful
      expect(r.headers).to eq(headers)
      expect(r.body).to eq('data')
    end
  end

  context 'inheritable formatters' do
    subject { described_class.new(app, formatters: { invalid: invalid_formatter }, content_types: { invalid: 'application/x-invalid' }) }

    let(:invalid_formatter) do
      Class.new do
        def self.call(_, _)
          { message: 'invalid' }.to_json
        end
      end
    end

    let(:app) { ->(_env) { [200, {}, ['']] } }
    let(:env) do
      Rack::MockRequest.env_for('/hello.invalid', 'HTTP_ACCEPT' => 'application/x-invalid')
    end

    it 'returns response by invalid formatter' do
      r = Rack::MockResponse[*subject.call(env)]
      expect(JSON.parse(r.body)).to eq('message' => 'invalid')
    end
  end

  context 'custom parser raises exception and rescue options are enabled for backtrace and original_exception' do
    it 'adds the backtrace and original_exception to the error output' do
      subject = described_class.new(
        app,
        rescue_options: { backtrace: true, original_exception: true },
        parsers: { json: ->(_object, _env) { raise StandardError, 'fail' } }
      )
      io = StringIO.new('{invalid}')
      error = catch(:error) do
        subject.call(
          Rack::PATH_INFO => '/info',
          Rack::REQUEST_METHOD => Rack::POST,
          'CONTENT_TYPE' => 'application/json',
          Rack::RACK_INPUT => io,
          'CONTENT_LENGTH' => io.length.to_s
        )
      end

      expect(error[:message]).to eq 'fail'
      expect(error[:backtrace].size).to be >= 1
      expect(error[:original_exception].class).to eq StandardError
    end
  end
end
