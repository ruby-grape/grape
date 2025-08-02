# frozen_string_literal: true

describe Grape::DSL::Helpers do
  subject { dummy_class }

  let(:dummy_class) do
    Class.new do
      extend Grape::DSL::Helpers

      def self.mods
        namespace_stackable(:helpers)
      end

      def self.first_mod
        mods.first
      end

      def self.namespace_stackable(key, value = nil)
        if value
          namespace_stackable_hash[key] << value
        else
          namespace_stackable_hash[key]
        end
      end

      def self.namespace_stackable_hash
        @namespace_stackable_hash ||= Hash.new do |hash, key|
          hash[key] = []
        end
      end
    end
  end

  let(:proc) do
    lambda do |*|
      def test
        :test
      end
    end
  end

  describe '.helpers' do
    it 'adds a module with the given block' do
      expect(subject).to receive(:namespace_stackable).with(:helpers, kind_of(Grape::DSL::Helpers::BaseHelper)).and_call_original
      expect(subject).to receive(:namespace_stackable).with(:helpers).and_call_original
      subject.helpers(&proc)

      expect(subject.first_mod.instance_methods).to include(:test)
    end

    it 'uses provided modules' do
      mod = Module.new

      expect(subject).to receive(:namespace_stackable).with(:helpers, kind_of(Grape::DSL::Helpers::BaseHelper)).and_call_original.twice
      expect(subject).to receive(:namespace_stackable).with(:helpers).and_call_original
      subject.helpers(mod, &proc)

      expect(subject.first_mod).to eq mod
    end

    it 'uses many provided modules' do
      mod  = Module.new
      mod2 = Module.new
      mod3 = Module.new

      expect(subject).to receive(:namespace_stackable).with(:helpers, kind_of(Grape::DSL::Helpers::BaseHelper)).and_call_original.exactly(4).times
      expect(subject).to receive(:namespace_stackable).with(:helpers).and_call_original.exactly(3).times

      subject.helpers(mod, mod2, mod3, &proc)

      expect(subject.mods).to include(mod)
      expect(subject.mods).to include(mod2)
      expect(subject.mods).to include(mod3)
    end

    context 'with an external file' do
      let(:boolean_helper) do
        Module.new do
          extend Grape::API::Helpers

          params :requires_toggle_prm do
            requires :toggle_prm, type: Boolean
          end
        end
      end

      it 'sets Boolean as a Grape::API::Boolean' do
        subject.helpers boolean_helper
        expect(subject.first_mod::Boolean).to eq Grape::API::Boolean
      end
    end

    context 'in child classes' do
      let(:base_class) do
        Class.new(Grape::API) do
          helpers do
            params :requires_toggle_prm do
              requires :toggle_prm, type: Integer
            end
          end
        end
      end

      let(:api_class) do
        Class.new(base_class) do
          params do
            use :requires_toggle_prm
          end
        end
      end

      it 'is available' do
        expect { api_class }.not_to raise_exception
      end
    end

    context 'public scope' do
      it 'returns helpers only' do
        expect(Class.new { extend Grape::DSL::Helpers }.singleton_methods - Class.methods).to contain_exactly(:helpers)
      end
    end
  end
end
