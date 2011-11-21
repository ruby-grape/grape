require 'spec_helper'

describe Grape::Middleware::Versioner::Path do
  let(:app) { lambda{|env| [200, env, env['api.version']]} }
  subject { Grape::Middleware::Versioner::Path.new(app, @options || {}) }

  it 'should set the API version based on the first path' do
    subject.call('PATH_INFO' => '/v1/awesome').last.should == 'v1'
  end

  it 'should cut the version out of the path' do
    subject.call('PATH_INFO' => '/v1/awesome')[1]['PATH_INFO'].should == '/awesome'
  end

  it 'should provide a nil version if no path is given' do
    subject.call('PATH_INFO' => '/').last.should be_nil
  end

  context 'with a pattern' do
    before{ @options = {:pattern => /v./i} }
    it 'should set the version if it matches' do
      subject.call('PATH_INFO' => '/v1/awesome').last.should == 'v1'
    end

    it 'should ignore the version if it fails to match' do
      subject.call('PATH_INFO' => '/awesome/radical').last.should be_nil
    end
  end

  context 'with specified versions' do
    before{ @options = {:versions => ['v1', 'v2']}}
    it 'should throw an error if a non-allowed version is specified' do
      catch(:error){subject.call('PATH_INFO' => '/v3/awesome')}[:status].should == 404
    end

    it 'should allow versions that have been specified' do
      subject.call('PATH_INFO' => '/v1/asoasd').last.should == 'v1'
    end
  end
end