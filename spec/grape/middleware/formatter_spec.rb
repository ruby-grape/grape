require 'spec_helper'

describe Grape::Middleware::Formatter do
  subject { Grape::Middleware::Formatter.new(app) }
  before { allow(subject).to receive(:dup).and_return(subject) }

  let(:app) { lambda { |env| [200, {}, [@body || { "foo" => "bar" }]] } }

  context 'serialization' do
    it 'looks at the bodies for possibly serializable data' do
      @body = { "abc" => "def" }
      _, _, bodies = *subject.call('PATH_INFO' => '/somewhere', 'HTTP_ACCEPT' => 'application/json')
      bodies.each { |b| expect(b).to eq(MultiJson.dump(@body)) }
    end

    it 'calls #to_json since default format is json' do
      @body = ['foo']
      @body.instance_eval do
        def to_json
          "\"bar\""
        end
      end

      subject.call('PATH_INFO' => '/somewhere', 'HTTP_ACCEPT' => 'application/json').last.each { |b| expect(b).to eq('"bar"') }
    end

    it 'calls #to_json if the content type is jsonapi' do
      @body = { 'foos' => [{ 'bar' => 'baz' }] }
      @body.instance_eval do
        def to_json
          "{\"foos\":[{\"bar\":\"baz\"}] }"
        end
      end

      subject.call('PATH_INFO' => '/somewhere', 'HTTP_ACCEPT' => 'application/vnd.api+json').last.each { |b| expect(b).to eq('{"foos":[{"bar":"baz"}] }') }
    end

    it 'calls #to_xml if the content type is xml' do
      @body = "string"
      @body.instance_eval do
        def to_xml
          "<bar/>"
        end
      end

      subject.call('PATH_INFO' => '/somewhere.xml', 'HTTP_ACCEPT' => 'application/json').last.each { |b| expect(b).to eq('<bar/>') }
    end
  end

  context 'error handling' do
    let(:formatter) { double(:formatter) }
    before do
      allow(Grape::Formatter::Base).to receive(:formatter_for) { formatter }
    end

    it 'rescues formatter-specific exceptions' do
      allow(formatter).to receive(:call) { raise Grape::Exceptions::InvalidFormatter.new(String, 'xml') }

      expect {
        catch(:error) { subject.call('PATH_INFO' => '/somewhere.xml', 'HTTP_ACCEPT' => 'application/json') }
      }.to_not raise_error
    end

    it 'does not rescue other exceptions' do
      allow(formatter).to receive(:call) { raise StandardError }

      expect {
        catch(:error) { subject.call('PATH_INFO' => '/somewhere.xml', 'HTTP_ACCEPT' => 'application/json') }
      }.to raise_error
    end
  end

  context 'detection' do

    it 'uses the xml extension if one is provided' do
      subject.call('PATH_INFO' => '/info.xml')
      expect(subject.env['api.format']).to eq(:xml)
    end

    it 'uses the json extension if one is provided' do
      subject.call('PATH_INFO' => '/info.json')
      expect(subject.env['api.format']).to eq(:json)
    end

    it 'uses the format parameter if one is provided' do
      subject.call('PATH_INFO' => '/info', 'QUERY_STRING' => 'format=json')
      expect(subject.env['api.format']).to eq(:json)
      subject.call('PATH_INFO' => '/info', 'QUERY_STRING' => 'format=xml')
      expect(subject.env['api.format']).to eq(:xml)
    end

    it 'uses the default format if none is provided' do
      subject.call('PATH_INFO' => '/info')
      expect(subject.env['api.format']).to eq(:txt)
    end

    it 'uses the requested format if provided in headers' do
      subject.call('PATH_INFO' => '/info', 'HTTP_ACCEPT' => 'application/json')
      expect(subject.env['api.format']).to eq(:json)
    end

    it 'uses the file extension format if provided before headers' do
      subject.call('PATH_INFO' => '/info.txt', 'HTTP_ACCEPT' => 'application/json')
      expect(subject.env['api.format']).to eq(:txt)
    end
  end

  context 'accept header detection' do
    it 'detects from the Accept header' do
      subject.call('PATH_INFO' => '/info', 'HTTP_ACCEPT' => 'application/xml')
      expect(subject.env['api.format']).to eq(:xml)
    end

    it 'looks for case-indifferent headers' do
      subject.call('PATH_INFO' => '/info', 'http_accept' => 'application/xml')
      expect(subject.env['api.format']).to eq(:xml)
    end

    it 'uses quality rankings to determine formats' do
      subject.call('PATH_INFO' => '/info', 'HTTP_ACCEPT' => 'application/json; q=0.3,application/xml; q=1.0')
      expect(subject.env['api.format']).to eq(:xml)
      subject.call('PATH_INFO' => '/info', 'HTTP_ACCEPT' => 'application/json; q=1.0,application/xml; q=0.3')
      expect(subject.env['api.format']).to eq(:json)
    end

    it 'handles quality rankings mixed with nothing' do
      subject.call('PATH_INFO' => '/info', 'HTTP_ACCEPT' => 'application/json,application/xml; q=1.0')
      expect(subject.env['api.format']).to eq(:xml)
    end

    it 'parses headers with other attributes' do
      subject.call('PATH_INFO' => '/info', 'HTTP_ACCEPT' => 'application/json; abc=2.3; q=1.0,application/xml; q=0.7')
      expect(subject.env['api.format']).to eq(:json)
    end

    it 'parses headers with vendor and api version' do
      subject.call('PATH_INFO' => '/info', 'HTTP_ACCEPT' => 'application/vnd.test-v1+xml')
      expect(subject.env['api.format']).to eq(:xml)
    end

    it 'parses headers with symbols as hash keys' do
      subject.call('PATH_INFO' => '/info', 'http_accept' => 'application/xml', system_time: '091293')
      expect(subject.env[:system_time]).to eq('091293')
    end
  end

  context 'content-type' do
    it 'is set for json' do
      _, headers, _ = subject.call('PATH_INFO' => '/info.json')
      expect(headers['Content-type']).to eq('application/json')
    end
    it 'is set for xml' do
      _, headers, _ = subject.call('PATH_INFO' => '/info.xml')
      expect(headers['Content-type']).to eq('application/xml')
    end
    it 'is set for txt' do
      _, headers, _ = subject.call('PATH_INFO' => '/info.txt')
      expect(headers['Content-type']).to eq('text/plain')
    end
    it 'is set for custom' do
      subject.options[:content_types] = {}
      subject.options[:content_types][:custom] = 'application/x-custom'
      _, headers, _ = subject.call('PATH_INFO' => '/info.custom')
      expect(headers['Content-type']).to eq('application/x-custom')
    end
  end

  context 'format' do
    it 'uses custom formatter' do
      subject.options[:content_types] = {}
      subject.options[:content_types][:custom] = "don't care"
      subject.options[:formatters][:custom] = lambda { |obj, env| 'CUSTOM FORMAT' }
      _, _, body = subject.call('PATH_INFO' => '/info.custom')
      expect(body.body).to eq(['CUSTOM FORMAT'])
    end
    it 'uses default json formatter' do
      @body = ['blah']
      _, _, body = subject.call('PATH_INFO' => '/info.json')
      expect(body.body).to eq(['["blah"]'])
    end
    it 'uses custom json formatter' do
      subject.options[:formatters][:json] = lambda { |obj, env| 'CUSTOM JSON FORMAT' }
      _, _, body = subject.call('PATH_INFO' => '/info.json')
      expect(body.body).to eq(['CUSTOM JSON FORMAT'])
    end
  end

  context 'input' do
    ["POST", "PATCH", "PUT", "DELETE"].each do |method|
      ["application/json", "application/json; charset=utf-8"].each do |content_type|
        context content_type do
          it 'parses the body from #{method} and copies values into rack.request.form_hash' do
            io = StringIO.new('{"is_boolean":true,"string":"thing"}')
            subject.call(
              'PATH_INFO' => '/info',
              'REQUEST_METHOD' => method,
              'CONTENT_TYPE' => content_type,
              'rack.input' => io,
              'CONTENT_LENGTH' => io.length
            )
            expect(subject.env['rack.request.form_hash']['is_boolean']).to be true
            expect(subject.env['rack.request.form_hash']['string']).to eq('thing')
          end
        end
      end
      it "parses the chunked body from #{method} and copies values into rack.request.from_hash" do
        io = StringIO.new('{"is_boolean":true,"string":"thing"}')
        subject.call(
          'PATH_INFO' => '/infol',
          'REQUEST_METHOD' => method,
          'CONTENT_TYPE' => 'application/json',
          'rack.input' => io,
          'HTTP_TRANSFER_ENCODING' => 'chunked'
        )
        expect(subject.env['rack.request.form_hash']['is_boolean']).to be true
        expect(subject.env['rack.request.form_hash']['string']).to eq('thing')
      end
      it "rewinds IO" do
        io = StringIO.new('{"is_boolean":true,"string":"thing"}')
        io.read
        subject.call(
          'PATH_INFO' => '/infol',
          'REQUEST_METHOD' => method,
          'CONTENT_TYPE' => 'application/json',
          'rack.input' => io,
          'HTTP_TRANSFER_ENCODING' => 'chunked'
        )
        expect(subject.env['rack.request.form_hash']['is_boolean']).to be true
        expect(subject.env['rack.request.form_hash']['string']).to eq('thing')
      end
      it 'parses the body from an xml #{method} and copies values into rack.request.from_hash' do
        io = StringIO.new('<thing><name>Test</name></thing>')
        subject.call(
          'PATH_INFO' => '/info.xml',
          'REQUEST_METHOD' => method,
          'CONTENT_TYPE' => 'application/xml',
          'rack.input' => io,
          'CONTENT_LENGTH' => io.length
        )
        expect(subject.env['rack.request.form_hash']['thing']['name']).to eq('Test')
      end
      [Rack::Request::FORM_DATA_MEDIA_TYPES, Rack::Request::PARSEABLE_DATA_MEDIA_TYPES].flatten.each do |content_type|
        it "ignores #{content_type}" do
          io = StringIO.new('name=Other+Test+Thing')
          subject.call(
            'PATH_INFO' => '/info',
            'REQUEST_METHOD' => method,
            'CONTENT_TYPE' => content_type,
            'rack.input' => io,
            'CONTENT_LENGTH' => io.length
          )
          expect(subject.env['rack.request.form_hash']).to be_nil
        end
      end
    end
  end

end
