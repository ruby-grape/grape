require 'spec_helper'

describe Grape::Middleware::Formatter do
  subject{ Grape::Middleware::Formatter.new(app) }
  before{ subject.stub!(:dup).and_return(subject) }

  let(:app){ lambda{|env| [200, {}, [@body]]} }

  context 'serialization' do
    it 'should look at the bodies for possibly serializable data' do
      @body = {"abc" => "def"}
      status, headers, bodies = *subject.call({'PATH_INFO' => '/somewhere', 'HTTP_ACCEPT' => 'application/json'})
      bodies.each{|b| b.should == MultiJson.encode(@body) }
    end

    it 'should call #to_json first if it is available' do
      @body = ['foo']
      @body.instance_eval do
        def to_json
          "\"bar\""
        end
      end

      subject.call({'PATH_INFO' => '/somewhere', 'HTTP_ACCEPT' => 'application/json'}).last.each{|b| b.should == '"bar"'}
    end

    it 'should serialize the #serializable_hash if that is available' do
      class SimpleExample
        def serializable_hash
          {:abc => 'def'}
        end
      end

      @body = [SimpleExample.new, SimpleExample.new]

      subject.call({'PATH_INFO' => '/somewhere', 'HTTP_ACCEPT' => 'application/json'}).last.each{|b| b.should == '[{"abc":"def"},{"abc":"def"}]'}
    end

    it 'should serialize multiple objects that respond to #serializable_hash' do
      class SimpleExample
        def serializable_hash
          {:abc => 'def'}
        end
      end

      @body = SimpleExample.new

      subject.call({'PATH_INFO' => '/somewhere', 'HTTP_ACCEPT' => 'application/json'}).last.each{|b| b.should == '{"abc":"def"}'}
    end

    it 'should call #to_xml if the content type is xml' do
      @body = "string"
      @body.instance_eval do
        def to_xml
          "<bar/>"
        end
      end

      subject.call({'PATH_INFO' => '/somewhere.xml', 'HTTP_ACCEPT' => 'application/json'}).last.each{|b| b.should == '<bar/>'}
    end
  end

  context 'detection' do
    it 'should use the extension if one is provided' do
      subject.call({'PATH_INFO' => '/info.xml'})
      subject.env['api.format'].should == :xml
      subject.call({'PATH_INFO' => '/info.json'})
      subject.env['api.format'].should == :json
    end

    it 'should use the default format if none is provided' do
      subject.call({'PATH_INFO' => '/info'})
      subject.env['api.format'].should == :txt
    end

    it 'should use the requested format if provided in headers' do
      subject.call({'PATH_INFO' => '/info', 'HTTP_ACCEPT' => 'application/json'})
      subject.env['api.format'].should == :json
    end

    it 'should use the file extension format if provided before headers' do
      subject.call({'PATH_INFO' => '/info.txt', 'HTTP_ACCEPT' => 'application/json'})
      subject.env['api.format'].should == :txt
    end
    
    it 'should throw an error on an unrecognized format' do
      err = catch(:error){ subject.call({'PATH_INFO' => '/info.barklar'}) }
      err.should == {:status => 406, :message => "The requested format is not supported."}
    end
  end

  context 'Accept header detection' do
    it 'should detect from the Accept header' do
      subject.call({'PATH_INFO' => '/info', 'HTTP_ACCEPT' => 'application/xml'})
      subject.env['api.format'].should == :xml
    end

    it 'should look for case-indifferent headers' do
      subject.call({'PATH_INFO' => '/info', 'http_accept' => 'application/xml'})
      subject.env['api.format'].should == :xml
    end

    it 'should use quality rankings to determine formats' do
      subject.call({'PATH_INFO' => '/info', 'HTTP_ACCEPT' => 'application/json; q=0.3,application/xml; q=1.0'})
      subject.env['api.format'].should == :xml
      subject.call({'PATH_INFO' => '/info', 'HTTP_ACCEPT' => 'application/json; q=1.0,application/xml; q=0.3'})
      subject.env['api.format'].should == :json
    end

    it 'should handle quality rankings mixed with nothing' do
      subject.call({'PATH_INFO' => '/info', 'HTTP_ACCEPT' => 'application/json,application/xml; q=1.0'})
      subject.env['api.format'].should == :xml
    end

    it 'should properly parse headers with other attributes' do
      subject.call({'PATH_INFO' => '/info', 'HTTP_ACCEPT' => 'application/json; abc=2.3; q=1.0,application/xml; q=0.7'})
      subject.env['api.format'].should == :json
    end

    it 'should properly parse headers with vendor and api version' do
      subject.call({'PATH_INFO' => '/info', 'HTTP_ACCEPT' => 'application/vnd.test-v1+xml'})
      subject.env['api.format'].should == :xml
    end
  end

  context 'Content-type' do
    it 'should be set for json' do
      _, headers, _ = subject.call({'PATH_INFO' => '/info.json'})
      headers['Content-type'].should == 'application/json'
    end
    it 'should be set for xml' do
      _, headers, _ = subject.call({'PATH_INFO' => '/info.xml'})
      headers['Content-type'].should == 'application/xml'
    end
    it 'should be set for txt' do
      _, headers, _ = subject.call({'PATH_INFO' => '/info.txt'})
      headers['Content-type'].should == 'text/plain'
    end
    it 'should be set for custom' do
      subject.options[:content_types][:custom] = 'application/x-custom'
      _, headers, _ = subject.call({'PATH_INFO' => '/info.custom'})
      headers['Content-type'].should == 'application/x-custom'
    end
  end

  context 'Format' do
    it 'should use custom formatter' do
      subject.options[:content_types][:custom] = "don't care"
      subject.options[:formatters][:custom] = lambda { |obj| 'CUSTOM FORMAT' }
      _, _, body = subject.call({'PATH_INFO' => '/info.custom'})
      body.body.should == ['CUSTOM FORMAT']
    end
    it 'should use default json formatter' do
      @body = ['blah']
      _, _, body = subject.call({'PATH_INFO' => '/info.json'})
      body.body.should == ['["blah"]']
    end
    it 'should use custom json formatter' do
      subject.options[:formatters][:json] = lambda { |obj| 'CUSTOM JSON FORMAT' }
      _, _, body = subject.call({'PATH_INFO' => '/info.json'})
      body.body.should == ['CUSTOM JSON FORMAT']
    end
  end

  context 'Input' do
    it 'should parse the body from a POST/PUT and put the contents into rack.request.form_hash' do
      subject.call({'PATH_INFO' => '/info', 'HTTP_ACCEPT' => 'application/json', 'rack.input' => StringIO.new('{"is_boolean":true,"string":"thing"}')})
      subject.env['rack.request.form_hash']['is_boolean'].should be_true
      subject.env['rack.request.form_hash']['string'].should == 'thing'
    end
    it 'should parse the body from an xml POST/PUT and put the contents into rack.request.from_hash' do
      subject.call({'PATH_INFO' => '/info.xml', 'HTTP_ACCEPT' => 'application/xml', 'rack.input' => StringIO.new('<thing><name>Test</name></thing>')})
      subject.env['rack.request.form_hash']['thing']['name'].should == 'Test'
    end
    it 'should be able to fail gracefully if the body is regular POST content' do
      subject.call({'PATH_INFO' => '/info', 'HTTP_ACCEPT' => 'application/json', 'rack.input' => StringIO.new('name=Other+Test+Thing')})
      subject.env['rack.request.form_hash'].should be_nil
    end
  end
end
