# frozen_string_literal: true

describe Grape::DSL::Middleware do
  subject { dummy_class }

  let(:dummy_class) do
    Class.new do
      include Grape::DSL::Middleware
    end
  end

  let(:proc) { -> {} }
  let(:foo_middleware) { Class.new }
  let(:bar_middleware) { Class.new }

  describe '.use' do
    it 'adds a middleware with the right operation' do
      expect(subject).to receive(:namespace_stackable).with(:middleware, [:use, foo_middleware, :arg1, proc])

      subject.use foo_middleware, :arg1, &proc
    end
  end

  describe '.insert' do
    it 'adds a middleware with the right operation' do
      expect(subject).to receive(:namespace_stackable).with(:middleware, [:insert, 0, :arg1, proc])

      subject.insert 0, :arg1, &proc
    end
  end

  describe '.insert_before' do
    it 'adds a middleware with the right operation' do
      expect(subject).to receive(:namespace_stackable).with(:middleware, [:insert_before, foo_middleware, :arg1, proc])

      subject.insert_before foo_middleware, :arg1, &proc
    end
  end

  describe '.insert_after' do
    it 'adds a middleware with the right operation' do
      expect(subject).to receive(:namespace_stackable).with(:middleware, [:insert_after, foo_middleware, :arg1, proc])

      subject.insert_after foo_middleware, :arg1, &proc
    end
  end

  describe '.middleware' do
    it 'returns the middleware stack' do
      subject.use foo_middleware, :arg1, &proc
      subject.insert_before bar_middleware, :arg1, :arg2

      expect(subject.middleware).to eq [[:use, foo_middleware, :arg1, proc], [:insert_before, bar_middleware, :arg1, :arg2]]
    end
  end
end
