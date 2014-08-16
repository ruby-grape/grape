require 'spec_helper'

module Grape
  module DSL
    module ValidationsSpec
      class Dummy
        include Grape::DSL::Validations

        def self.settings
          @settings ||= Grape::Util::HashStack.new
        end
      end
    end

    describe Validations do
      subject { ValidationsSpec::Dummy }

      describe '.reset_validations!' do
        before do
          subject.settings.peek[:declared_params] = ['dummy']
          subject.settings.peek[:validations] = ['dummy']
          subject.reset_validations!
        end

        it 'resets declared params' do
          expect(subject.settings.peek[:declared_params]).to be_empty
        end

        it 'resets validations' do
          expect(subject.settings.peek[:validations]).to be_empty
        end
      end

      describe '.params' do
        it 'returns a ParamsScope' do
          expect(subject.params).to be_a Grape::Validations::ParamsScope
        end

        it 'evaluates block' do
          expect { subject.params { raise 'foo' } }.to raise_error RuntimeError, 'foo'
        end
      end

      describe '.document_attribute' do
        before do
          subject.document_attribute([full_name: 'xxx'], foo: 'bar')
        end

        it 'creates last_description' do
          expect(subject.instance_variable_get(:'@last_description')).to eq(params: { 'xxx' => { foo: 'bar' } })
        end
      end
    end
  end
end
