require 'spec_helper'

module Grape
  module DSL
    module ValidationsSpec
      class Dummy
        include Grape::DSL::Validations
      end
    end

    describe Validations do
      subject { ValidationsSpec::Dummy }

      describe '.reset_validations!' do
        before do
          subject.namespace_stackable :declared_params, ['dummy']
          subject.namespace_stackable :validations, ['dummy']
          subject.reset_validations!
        end

        it 'resets declared params' do
          expect(subject.namespace_stackable(:declared_params)).to eq []
        end

        it 'resets validations' do
          expect(subject.namespace_stackable(:validations)).to eq []
        end
      end

      describe '.params' do
        it 'returns a ParamsScope' do
          expect(subject.params).to be_a Grape::Validations::ParamsScope
        end

        it 'evaluates block' do
          expect { subject.params { fail 'foo' } }.to raise_error RuntimeError, 'foo'
        end
      end

      describe '.document_attribute' do
        before do
          subject.document_attribute([full_name: 'xxx'], foo: 'bar')
        end

        it 'creates a param documentation' do
          expect(subject.namespace_stackable(:params)).to eq(['xxx' => { foo: 'bar' }])
          expect(subject.route_setting(:description)).to eq(params: { 'xxx' => { foo: 'bar' } })
        end
      end
    end
  end
end
