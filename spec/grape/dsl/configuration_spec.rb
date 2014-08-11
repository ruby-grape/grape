require 'spec_helper'

module Grape
  module DSL
    module ConfigurationSpec
      class Dummy
        include Grape::DSL::Configuration

        # rubocop:disable TrivialAccessors
        def self.last_desc
          @last_description
        end
        # rubocop:enable TrivialAccessors
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
      end

      describe '.desc' do
        it 'sets a description' do
          options = { message: 'none' }
          subject.desc options
          expect(subject.last_desc).to eq(description: options)
        end
      end

    end
  end
end
