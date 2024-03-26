# frozen_string_literal: true

describe Grape::Middleware::Stack do
  subject { described_class.new }

  let(:foo_middleware) { Class.new }
  let(:bar_middleware) { Class.new }
  let(:block_middleware) do
    Class.new do
      attr_reader :block

      def initialize(&block)
        @block = block
      end
    end
  end
  let(:proc) { -> {} }
  let(:others) { [[:use, bar_middleware], [:insert_before, bar_middleware, block_middleware, proc]] }

  before do
    subject.use foo_middleware
  end

  describe '#use' do
    it 'pushes a middleware class onto the stack' do
      expect { subject.use bar_middleware }
        .to change(subject, :size).by(1)
      expect(subject.last).to eq(bar_middleware)
    end

    it 'pushes a middleware class with arguments onto the stack' do
      expect { subject.use bar_middleware, false, my_arg: 42 }
        .to change(subject, :size).by(1)
      expect(subject.last).to eq(bar_middleware)
      expect(subject.last.args).to eq([false, { my_arg: 42 }])
    end

    it 'pushes a middleware class with block arguments onto the stack' do
      expect { subject.use block_middleware, &proc }
        .to change(subject, :size).by(1)
      expect(subject.last).to eq(block_middleware)
      expect(subject.last.args).to eq([])
      expect(subject.last.block).to eq(proc)
    end
  end

  describe '#insert' do
    it 'inserts a middleware class at the integer index' do
      expect { subject.insert 0, bar_middleware }
        .to change(subject, :size).by(1)
      expect(subject[0]).to eq(bar_middleware)
      expect(subject[1]).to eq(foo_middleware)
    end
  end

  describe '#insert_before' do
    it 'inserts a middleware before another middleware class' do
      expect { subject.insert_before foo_middleware, bar_middleware }
        .to change(subject, :size).by(1)
      expect(subject[0]).to eq(bar_middleware)
      expect(subject[1]).to eq(foo_middleware)
    end

    it 'inserts a middleware before an anonymous class given by its superclass' do
      subject.use Class.new(block_middleware)

      expect { subject.insert_before block_middleware, bar_middleware }
        .to change(subject, :size).by(1)

      expect(subject[1]).to eq(bar_middleware)
      expect(subject[2]).to eq(block_middleware)
    end

    it 'raises an error on an invalid index' do
      stub_const('StackSpec::BlockMiddleware', block_middleware)
      expect { subject.insert_before block_middleware, bar_middleware }
        .to raise_error(RuntimeError, 'No such middleware to insert before: StackSpec::BlockMiddleware')
    end
  end

  describe '#insert_after' do
    it 'inserts a middleware after another middleware class' do
      expect { subject.insert_after foo_middleware, bar_middleware }
        .to change(subject, :size).by(1)
      expect(subject[1]).to eq(bar_middleware)
      expect(subject[0]).to eq(foo_middleware)
    end

    it 'inserts a middleware after an anonymous class given by its superclass' do
      subject.use Class.new(block_middleware)

      expect { subject.insert_after block_middleware, bar_middleware }
        .to change(subject, :size).by(1)

      expect(subject[1]).to eq(block_middleware)
      expect(subject[2]).to eq(bar_middleware)
    end

    it 'raises an error on an invalid index' do
      stub_const('StackSpec::BlockMiddleware', block_middleware)
      expect { subject.insert_after block_middleware, bar_middleware }
        .to raise_error(RuntimeError, 'No such middleware to insert after: StackSpec::BlockMiddleware')
    end
  end

  describe '#merge_with' do
    it 'applies a collection of operations and middlewares' do
      expect { subject.merge_with(others) }
        .to change(subject, :size).by(2)
      expect(subject[0]).to eq(foo_middleware)
      expect(subject[1]).to eq(block_middleware)
      expect(subject[2]).to eq(bar_middleware)
    end

    context 'middleware spec with proc declaration exists' do
      let(:middleware_spec_with_proc) { [:use, foo_middleware, proc] }

      it 'properly forwards spec arguments' do
        expect(subject).to receive(:use).with(foo_middleware)
        subject.merge_with([middleware_spec_with_proc])
      end
    end
  end

  describe '#build' do
    it 'returns a rack builder instance' do
      expect(subject.build).to be_instance_of(Rack::Builder)
    end

    context 'when @others are present' do
      let(:others) { [[:insert_after, Grape::Middleware::Formatter, bar_middleware]] }

      it 'applies the middleware specs stored in @others' do
        subject.concat others
        subject.use Grape::Middleware::Formatter
        subject.build
        expect(subject[0]).to eq foo_middleware
        expect(subject[1]).to eq Grape::Middleware::Formatter
        expect(subject[2]).to eq bar_middleware
      end
    end
  end

  describe '#concat' do
    it 'adds non :use specs to @others' do
      expect { subject.concat others }.to change(subject, :others).from([]).to([[others.last]])
    end

    it 'calls +merge_with+ with the :use specs' do
      expect(subject).to receive(:merge_with).with [[:use, bar_middleware]]
      subject.concat others
    end
  end
end
