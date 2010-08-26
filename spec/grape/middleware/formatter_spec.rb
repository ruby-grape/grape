require 'spec_helper'

describe Grape::Middleware::Formatter do
  subject{ Grape::Middleware::Formatter.new(app)}
  before{ subject.stub!(:dup).and_return(subject) }
  
  let(:app){ lambda{|env| [200, {}, [@body]]} }
  
  context 'serialization' do
    it 'should look at the bodies for possibly serializable data' do
      @body = {"abc" => "def"}
      status, headers, bodies = *subject.call({'PATH_INFO' => '/somewhere'})
      bodies.first.should == MultiJson.encode(@body)
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
      subject.env['api.format'].should == :json
    end
    
    it 'should throw an error on an unrecognized format' do
      err = catch(:error){ subject.call({'PATH_INFO' => '/info.barklar'}) }
      err.should == {:status => 406, :message => "The requested format is not supported."}
    end
  end
end