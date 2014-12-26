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

      describe '.use' do
        it 'adds a middleware' do
          expect(subject).to receive(:namespace_stackable).with(:middleware, [:my_middleware, :arg1, proc])

          subject.use :my_middleware, :arg1, &proc
        end
      end

      describe '.middleware' do
        it 'returns the middleware stack' do
          subject.use :my_middleware, :arg1, &proc

          expect(subject.middleware).to eq [[:my_middleware, :arg1, proc]]
        end
      end
    end
  end
end
