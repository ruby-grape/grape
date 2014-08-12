require 'spec_helper'

module Grape
  module DSL
    module ParametersSpec
      class Dummy
        include Grape::DSL::Parameters

        def validate_attributes(*args)
          @validate_attributes = *args
        end

        # rubocop:disable TrivialAccessors
        def validate_attrs
          @validate_attributes
        end
        # rubocop:enable TrivialAccessors

        def push_declared_params(*args)
          @push_declared_params = args
        end

        # rubocop:disable TrivialAccessors
        def push_declared_paras
          @push_declared_params
        end
        # rubocop:enable TrivialAccessors

        def validates(*args)
          @validates = *args
        end

        # rubocop:disable TrivialAccessors
        def valids
          @validates
        end
        # rubocop:enable TrivialAccessors
      end
    end

    describe Parameters do
      subject { ParametersSpec::Dummy.new }

      xdescribe '#use' do
        it 'does some thing'
      end

      xdescribe '#use_scope' do
        it 'does some thing'
      end

      xdescribe '#includes' do
        it 'does some thing'
      end

      describe '#requires' do
        it 'adds a required parameter' do
          subject.requires :id, type: Integer, desc: 'Identity.'

          expect(subject.validate_attrs).to eq([[:id], { type: Integer, desc: 'Identity.' }])
          expect(subject.push_declared_paras).to eq([[:id]])
        end
      end

      describe '#optional' do
        it 'adds an optional parameter' do
          subject.optional :id, type: Integer, desc: 'Identity.'

          expect(subject.valids).to eq([[:id], { type: Integer, desc: 'Identity.' }])
          expect(subject.push_declared_paras).to eq([[:id]])
        end
      end

      describe '#mutually_exclusive' do
        it 'adds an mutally exclusive parameter validation' do
          subject.mutually_exclusive :media, :audio

          expect(subject.valids).to eq([[:media, :audio], { mutual_exclusion: true }])
        end
      end

      describe '#exactly_one_of' do
        it 'adds an exactly of one parameter validation' do
          subject.exactly_one_of :media, :audio

          expect(subject.valids).to eq([[:media, :audio], { exactly_one_of: true }])
        end
      end

      describe '#at_least_one_of' do
        it 'adds an at least one of parameter validation' do
          subject.at_least_one_of :media, :audio

          expect(subject.valids).to eq([[:media, :audio], { at_least_one_of: true }])
        end
      end

      xdescribe '#group' do
        it 'does some thing'
      end

      xdescribe '#params' do
        it 'does some thing'
      end

    end
  end
end
