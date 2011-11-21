require 'spec_helper'

describe Grape::Middleware::Versioner do
  let(:klass) { Grape::Middleware::Versioner }
  it 'should recognize :path' do
    klass.using(:path).should == Grape::Middleware::Versioner::Path
  end

  it 'should recognize :header' do
    klass.using(:header).should == Grape::Middleware::Versioner::Header
  end
end