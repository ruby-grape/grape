# frozen_string_literal: true

describe Grape::DSL::Callbacks do
  subject { dummy_class }

  let(:dummy_class) do
    Class.new do
      include Grape::DSL::Callbacks
    end
  end

  let(:proc) { -> {} }

  describe '.before' do
    it 'adds a block to "before"' do
      expect(subject).to receive(:namespace_stackable).with(:befores, proc)
      subject.before(&proc)
    end
  end

  describe '.before_validation' do
    it 'adds a block to "before_validation"' do
      expect(subject).to receive(:namespace_stackable).with(:before_validations, proc)
      subject.before_validation(&proc)
    end
  end

  describe '.after_validation' do
    it 'adds a block to "after_validation"' do
      expect(subject).to receive(:namespace_stackable).with(:after_validations, proc)
      subject.after_validation(&proc)
    end
  end

  describe '.after' do
    it 'adds a block to "after"' do
      expect(subject).to receive(:namespace_stackable).with(:afters, proc)
      subject.after(&proc)
    end
  end
end
