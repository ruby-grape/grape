require 'spec_helper'
require 'hashie'

describe Grape::ParamsWrapper do
  before do
    p = Hashie::Mash.new(user: {id: 34, name: "Cherio"})
    @params = Grape::ParamsWrapper.new(p)
  end
  
  it "can read existing path" do
    val = @params.read('user.id')
    val.should == 34
  end
  
  it 'should return nil for unexsiting path' do
    @params.read('master.id').should == nil
    @params.read('user.another_id').should == nil
  end
  
  it 'can write value by existing path' do
    @params.write('user.id', 'something')
    @params.read('user.id').should == 'something'
  end
  
  it 'can tell if a path is defined' do
    @params.has_key?('user.id').should == true
    @params.has_key?('user.uid').should == false
    @params.has_key?('master.id').should == false
  end
  
  it 'should act as a hash' do
    @params['user']['id'].should == 34
  end
  
  # TODO: maybe later, could be useful
  # it 'can write value by unexisting path' do
  #   @params.write('master.id', '67klop')
  #   @params.read('master.id').should == '67klop'
  # end
  
end
