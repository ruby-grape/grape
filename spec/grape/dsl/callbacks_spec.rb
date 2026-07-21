# frozen_string_literal: true

describe Grape::DSL::Callbacks do
  subject { dummy_class }

  let(:dummy_class) do
    Class.new do
      extend Grape::DSL::Settings
      extend Grape::DSL::Callbacks
    end
  end

  let(:proc) { -> {} }

  describe '.before' do
    it 'adds a block to "before"' do
      subject.before(&proc)
      expect(subject.inheritable_setting.callbacks[:before]).to eq([proc])
    end
  end

  describe '.before_validation' do
    it 'adds a block to "before_validation"' do
      subject.before_validation(&proc)
      expect(subject.inheritable_setting.callbacks[:before_validation]).to eq([proc])
    end
  end

  describe '.after_validation' do
    it 'adds a block to "after_validation"' do
      subject.after_validation(&proc)
      expect(subject.inheritable_setting.callbacks[:after_validation]).to eq([proc])
    end
  end

  describe '.after' do
    it 'adds a block to "after"' do
      subject.after(&proc)
      expect(subject.inheritable_setting.callbacks[:after]).to eq([proc])
    end
  end

  describe '.finally' do
    it 'adds a block to "finally"' do
      subject.finally(&proc)
      expect(subject.inheritable_setting.callbacks[:finally]).to eq([proc])
    end
  end
end
