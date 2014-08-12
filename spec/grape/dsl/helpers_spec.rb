require 'spec_helper'

module Grape
  module DSL
    module HelpersSpec
      class Dummy
        include Grape::DSL::Helpers

        def self.settings
          @settings ||= Grape::Util::HashStack.new
        end

        def self.set(_, mod)
          @mod = mod
        end

        # rubocop:disable TrivialAccessors
        def self.mod
          @mod
        end
        # rubocop:enable TrivialAccessors
      end
    end
    describe Helpers do
      subject { Class.new(HelpersSpec::Dummy) }
      let(:proc) do
        ->(*) do
          def test
            :test
          end
        end
      end

      describe '.helpers' do
        it 'adds a module with the given block' do
          expect(subject).to receive(:set).with(:helpers, kind_of(Grape::DSL::Helpers::BaseHelper)).and_call_original
          subject.helpers(&proc)

          expect(subject.mod.instance_methods).to include(:test)
        end

        it 'uses provided modules' do
          mod = Module.new

          expect(subject).to receive(:set).with(:helpers,  kind_of(Grape::DSL::Helpers::BaseHelper)).and_call_original
          subject.helpers(mod, &proc)

          expect(subject.mod).not_to eq mod
          expect(subject.mod).to include mod
        end
      end
    end
  end
end
