# frozen_string_literal: true

describe Grape::DSL::Middleware do
  subject { dummy_class }

  let(:dummy_class) do
    Class.new do
      extend Grape::DSL::Middleware

      def self.namespace_stackable(key, value = nil)
        if value
          namespace_stackable_hash[key] << value
        else
          namespace_stackable_hash[key]
        end
      end

      def self.namespace_stackable_hash
        @namespace_stackable_hash ||= Hash.new do |hash, key|
          hash[key] = []
        end
      end
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
