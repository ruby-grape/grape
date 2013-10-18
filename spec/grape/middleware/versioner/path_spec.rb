require 'spec_helper'

describe Grape::Middleware::Versioner::Path do
  let(:app) { lambda { |env| [200, env, env['api.version']] } }
  subject { Grape::Middleware::Versioner::Path.new(app, @options || {}) }

  it 'sets the API version based on the first path' do
    subject.call('PATH_INFO' => '/v1/awesome').last.should == 'v1'
  end

  it 'does not cut the version out of the path' do
    subject.call('PATH_INFO' => '/v1/awesome')[1]['PATH_INFO'].should == '/v1/awesome'
  end

  it 'provides a nil version if no path is given' do
    subject.call('PATH_INFO' => '/').last.should be_nil
  end

  context 'with a pattern' do
    before { @options = { pattern: /v./i } }
    it 'sets the version if it matches' do
      subject.call('PATH_INFO' => '/v1/awesome').last.should == 'v1'
    end

    it 'ignores the version if it fails to match' do
      subject.call('PATH_INFO' => '/awesome/radical').last.should be_nil
    end
  end

  [['v1', 'v2'], [:v1, :v2], [:v1, 'v2'], ['v1', :v2]].each do |versions|
    context 'with specified versions as #{versions}' do
      before { @options = { versions: versions } }

      it 'throws an error if a non-allowed version is specified' do
        catch(:error) { subject.call('PATH_INFO' => '/v3/awesome') }[:status].should == 404
      end

      it 'allows versions that have been specified' do
        subject.call('PATH_INFO' => '/v1/asoasd').last.should == 'v1'
      end
    end
  end

end
