require 'spec_helper'

describe Grape::Middleware::Stack do
  module StackSpec
    class FooMiddleware; end
    class BarMiddleware; end
    class BlockMiddleware
      attr_reader :block
      def initialize(&block)
        @block = block
      end
    end
  end

  subject { Grape::Middleware::Stack.new }

  before do
    subject.use StackSpec::FooMiddleware
  end

  describe '#use' do
    it 'pushes a middleware class onto the stack' do
      expect { subject.use StackSpec::BarMiddleware }
        .to change { subject.size }.by(1)
      expect(subject.last).to eq(StackSpec::BarMiddleware)
    end

    it 'pushes a middleware class with arguments onto the stack' do
      expect { subject.use StackSpec::BarMiddleware, false, my_arg: 42 }
        .to change { subject.size }.by(1)
      expect(subject.last).to eq(StackSpec::BarMiddleware)
      expect(subject.last.args).to eq([false, { my_arg: 42 }])
    end

    it 'pushes a middleware class with block arguments onto the stack' do
      proc = ->() {}
      expect { subject.use StackSpec::BlockMiddleware, &proc }
        .to change { subject.size }.by(1)
      expect(subject.last).to eq(StackSpec::BlockMiddleware)
      expect(subject.last.args).to eq([])
      expect(subject.last.block).to eq(proc)
    end
  end

  describe '#insert' do
    it 'inserts a middleware class at the integer index' do
      expect { subject.insert 0, StackSpec::BarMiddleware }
        .to change { subject.size }.by(1)
      expect(subject[0]).to eq(StackSpec::BarMiddleware)
      expect(subject[1]).to eq(StackSpec::FooMiddleware)
    end
  end

  describe '#insert_before' do
    it 'inserts a middleware before another middleware class' do
      expect { subject.insert_before StackSpec::FooMiddleware, StackSpec::BarMiddleware }
        .to change { subject.size }.by(1)
      expect(subject[0]).to eq(StackSpec::BarMiddleware)
      expect(subject[1]).to eq(StackSpec::FooMiddleware)
    end

    it 'raises an error on an invalid index' do
      expect { subject.insert_before StackSpec::BlockMiddleware, StackSpec::BarMiddleware }
        .to raise_error(RuntimeError, 'No such middleware to insert before: StackSpec::BlockMiddleware')
    end
  end

  describe '#insert_after' do
    it 'inserts a middleware after another middleware class' do
      expect { subject.insert_after StackSpec::FooMiddleware, StackSpec::BarMiddleware }
        .to change { subject.size }.by(1)
      expect(subject[1]).to eq(StackSpec::BarMiddleware)
      expect(subject[0]).to eq(StackSpec::FooMiddleware)
    end

    it 'raises an error on an invalid index' do
      expect { subject.insert_after StackSpec::BlockMiddleware, StackSpec::BarMiddleware }
        .to raise_error(RuntimeError, 'No such middleware to insert after: StackSpec::BlockMiddleware')
    end
  end

  describe '#merge_with' do
    let(:proc) { ->() {} }
    let(:other) { [[:use, StackSpec::BarMiddleware], [:insert_before, StackSpec::BarMiddleware, StackSpec::BlockMiddleware, proc]] }

    it 'applies a collection of operations and middlewares' do
      expect { subject.merge_with(other) }
        .to change { subject.size }.by(2)
      expect(subject[0]).to eq(StackSpec::FooMiddleware)
      expect(subject[1]).to eq(StackSpec::BlockMiddleware)
      expect(subject[2]).to eq(StackSpec::BarMiddleware)
    end
  end
end
