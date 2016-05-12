require 'spec_helper'

module Grape
  module DSL
    module MiddlewareSpec
      class Dummy
        include Grape::DSL::Middleware
      end
    end

    describe Middleware do
      subject { Class.new(MiddlewareSpec::Dummy) }
      let(:proc) { ->() {} }
      let(:foo_middleware) { Class.new }
      let(:bar_middleware) { Class.new }

      describe '.use' do
        it 'adds a middleware with the right operation' do
          expect(subject).to receive(:namespace_stackable).with(:middleware, [:use, foo_middleware, :arg1, proc])

          subject.use foo_middleware, :arg1, &proc
        end

        context 'when the given class responds to +middleware_spec+' do
          let(:foo_middleware) do
            Class.new do
              def self.middleware_spec
                [:insert_after, Object, self]
              end
            end
          end

          it 'stores the return value of +middleware_spec+ with the given args and proc' do
            expect(subject).to receive(:namespace_stackable).with(:middleware, [:insert_after, Object, foo_middleware, :arg1, proc])
            subject.use foo_middleware, :arg1, &proc
          end
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
  end
end
