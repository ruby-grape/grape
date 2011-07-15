require 'spec_helper'

RSpec::Matchers.define :be_challenge do
  match do |actual_response|
    actual_response.status == 401 &&
    actual_response['WWW-Authenticate'] =~ /^Digest / &&
    actual_response.body.empty?
  end
end

class Test < Grape::API
  version '1'
  
  http_digest({:realm => 'Test Api', :opaque => 'secret'}) do |username|
    {'foo' => 'bar'}[username]
  end

  get '/test' do
    [{:hey => 'you'},{:there => 'bar'},{:foo => 'baz'}]
  end
end

describe Grape::Middleware::Auth::Digest do
  def app
    Test
  end
  
  it 'should be a digest authentication challenge' do
    get '/1/test'
    last_response.should be_challenge
  end
  
  it 'should throw a 401 if no auth is given' do
    get '/1/test'
    last_response.status.should == 401
  end

  it 'should authenticate if given valid creds' do
    digest_authorize "foo", "bar"
    get '/1/test'
    last_response.status.should == 200
  end

  it 'should throw a 401 if given invalid creds' do
    digest_authorize "bar", "foo"
    get '/1/test'
    last_response.status.should == 401
  end
end
