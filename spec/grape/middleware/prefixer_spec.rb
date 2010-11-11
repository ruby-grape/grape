require 'spec_helper'

describe Grape::Middleware::Prefixer do
  let(:app){ lambda{|env| [200, {}, env['PATH_INFO']]} }
  subject{ Grape::Middleware::Prefixer.new(app, @options || {}) }

  it 'should lop off a prefix (without a slash)' do
    @options = {:prefix => 'monkey'}
    subject.call('PATH_INFO' => '/monkey/beeswax').last.should == '/beeswax'
  end
  
  it 'should lop off a prefix (with a slash)' do
    @options = {:prefix => '/banana'}
    subject.call('PATH_INFO' => '/banana/peel').last.should == '/peel'
  end
  
  it 'should not lop off non-prefixes' do
    @options = {:prefix => '/monkey'}
    subject.call('PATH_INFO' => '/banana/peel').last.should == '/banana/peel'
  end
  
  it 'should pass through unaltered if there is no prefix' do
    subject.call('PATH_INFO' => '/awesome').last.should == '/awesome'
  end
  
  it 'should only remove the first instance of the prefix' do
    @options = {:prefix => 'api'}
    subject.call('PATH_INFO' => '/api/v1/api/awesome').last.should == '/v1/api/awesome'
  end
end