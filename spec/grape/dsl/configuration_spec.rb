require 'spec_helper'

module Grape
  module DSL
    module ConfigurationSpec
      class Dummy
        include Grape::DSL::Configuration
      end
    end
    describe Configuration do
      subject { Class.new(ConfigurationSpec::Dummy) }
      let(:logger) { double(:logger) }

      describe '.logger' do
        it 'sets a logger' do
          subject.logger logger
          expect(subject.logger).to eq logger
        end

        it 'returns a logger' do
          expect(subject.logger logger).to eq logger
        end
      end

      describe '.desc' do
        it 'sets a description' do
          options = { message: 'none' }
          subject.desc options
          expect(subject.namespace_setting(:description)).to eq(description: options)
          expect(subject.route_setting(:description)).to eq(description: options)
        end
      end

    end
  end
end
