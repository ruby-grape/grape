require 'spec_helper'

module Grape
  module DSL
    module ParametersSpec
      class Dummy
        include Grape::DSL::Parameters
      end
    end

    describe Parameters do
      subject { Class.new(ParametersSpec::Dummy) }

      xdescribe '.use' do
        it 'does some thing'
      end

      xdescribe '.use_scope' do
        it 'does some thing'
      end

      xdescribe '.includes' do
        it 'does some thing'
      end

      xdescribe '.requires' do
        it 'does some thing'
      end

      xdescribe '.optional' do
        it 'does some thing'
      end

      xdescribe '.mutually_exclusive' do
        it 'does some thing'
      end

      xdescribe '.exactly_one_of' do
        it 'does some thing'
      end

      xdescribe '.at_least_one_of' do
        it 'does some thing'
      end

      xdescribe '.group' do
        it 'does some thing'
      end

      xdescribe '.params' do
        it 'does some thing'
      end

    end
  end
end
