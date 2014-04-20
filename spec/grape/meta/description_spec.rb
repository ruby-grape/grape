require 'spec_helper'

describe Grape::Meta::Description do
  subject { Grape::Meta::Description.new }

  describe '#detail' do
    it 'should set when a value is provided' do
      subject.detail 'this is detail'
      expect(subject.detail).to eq('this is detail')
    end

    it 'should blank when nil is provided' do
      subject.detail 'foo'
      subject.detail nil
      expect(subject.detail).to eq(nil)
    end
  end

  describe '#summary' do
    it 'should be settable in the constructor' do
      expect(Grape::Meta::Description.new('foo').summary).to eq('foo')
    end
  end
end
