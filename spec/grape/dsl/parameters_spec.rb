require 'spec_helper'

module Grape
  module DSL
    module ParametersSpec
      class Dummy
        include Grape::DSL::Parameters
        attr_accessor :api

        def validate_attributes(*args)
          @validate_attributes = *args
        end

        # rubocop:disable TrivialAccessors
        def validate_attributes_reader
          @validate_attributes
        end
        # rubocop:enable TrivialAccessors

        def push_declared_params(*args)
          @push_declared_params = args
        end

        # rubocop:disable TrivialAccessors
        def push_declared_params_reader
          @push_declared_params
        end
        # rubocop:enable TrivialAccessors

        def validates(*args)
          @validates = *args
        end

        # rubocop:disable TrivialAccessors
        def validates_reader
          @validates
        end
        # rubocop:enable TrivialAccessors
      end
    end

    describe Parameters do
      subject { ParametersSpec::Dummy.new }

      describe '#use' do
        before { allow(subject.api).to receive(:namespace_stackable).with(:named_params) }
        let(:options) { { option: 'value' } }
        let(:named_params) { { params_group: proc {} } }

        it 'calls processes associated with named params' do
          allow(Grape::DSL::Configuration).to receive(:stacked_hash_to_hash).and_return(named_params)
          expect(subject).to receive(:instance_exec).with(options).and_yield
          subject.use :params_group, options
        end

        it 'raises error when non-existent named param is called' do
          allow(Grape::DSL::Configuration).to receive(:stacked_hash_to_hash).and_return({})
          expect { subject.use :params_group }.to raise_error('Params :params_group not found!')
        end
      end

      describe '#use_scope' do
        it 'is alias to #use' do
          expect(subject.method(:use_scope)).to eq subject.method(:use)
        end
      end

      describe '#includes' do
        it 'is alias to #use' do
          expect(subject.method(:includes)).to eq subject.method(:use)
        end
      end

      describe '#requires' do
        it 'adds a required parameter' do
          subject.requires :id, type: Integer, desc: 'Identity.'

          expect(subject.validate_attributes_reader).to eq([[:id], { type: Integer, desc: 'Identity.', presence: true }])
          expect(subject.push_declared_params_reader).to eq([[:id]])
        end
      end

      describe '#optional' do
        it 'adds an optional parameter' do
          subject.optional :id, type: Integer, desc: 'Identity.'

          expect(subject.validate_attributes_reader).to eq([[:id], { type: Integer, desc: 'Identity.' }])
          expect(subject.push_declared_params_reader).to eq([[:id]])
        end
      end

      describe '#mutually_exclusive' do
        it 'adds an mutally exclusive parameter validation' do
          subject.mutually_exclusive :media, :audio

          expect(subject.validates_reader).to eq([[:media, :audio], { mutual_exclusion: true }])
        end
      end

      describe '#exactly_one_of' do
        it 'adds an exactly of one parameter validation' do
          subject.exactly_one_of :media, :audio

          expect(subject.validates_reader).to eq([[:media, :audio], { exactly_one_of: true }])
        end
      end

      describe '#at_least_one_of' do
        it 'adds an at least one of parameter validation' do
          subject.at_least_one_of :media, :audio

          expect(subject.validates_reader).to eq([[:media, :audio], { at_least_one_of: true }])
        end
      end

      describe '#all_or_none_of' do
        it 'adds an all or none of parameter validation' do
          subject.all_or_none_of :media, :audio

          expect(subject.validates_reader).to eq([[:media, :audio], { all_or_none_of: true }])
        end
      end

      describe '#group' do
        it 'is alias to #requires' do
          expect(subject.method(:group)).to eq subject.method(:requires)
        end
      end

      xdescribe '#params' do
        it 'does some thing'
      end
    end
  end
end
