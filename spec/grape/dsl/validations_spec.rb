# frozen_string_literal: true

describe Grape::DSL::Validations do
  subject { dummy_class }

  let(:dummy_class) do
    Class.new do
      extend Grape::DSL::Validations
      def self.unset_namespace_stackable(_key); end
    end
  end

  describe '.reset_validations' do
    subject { dummy_class.reset_validations! }

    it 'calls unset_namespace_stackable properly' do
      expect(dummy_class).to receive(:unset_namespace_stackable).with(:declared_params)
      expect(dummy_class).to receive(:unset_namespace_stackable).with(:params)
      expect(dummy_class).to receive(:unset_namespace_stackable).with(:validations)
      subject
    end
  end

  describe '.params' do
    subject { dummy_class.params { :my_block } }

    it 'creates a proper Grape::Validations::ParamsScope' do
      expect(Grape::Validations::ParamsScope).to receive(:new).with(api: dummy_class, type: Hash) do |_func, &block|
        expect(block.call).to eq(:my_block)
      end.and_return(:param_scope)
      expect(subject).to eq(:param_scope)
    end
  end

  describe '.contract' do
    context 'when contract is nil and blockless' do
      it 'raises an ArgumentError' do
        expect { dummy_class.contract }.to raise_error(ArgumentError, 'Either contract or block must be provided')
      end
    end

    context 'when contract is nil and but a block is provided' do
      it 'returns a proper rape::Validations::ContractScope' do
        expect(Grape::Validations::ContractScope).to receive(:new).with(dummy_class, nil) do |_func, &block|
          expect(block.call).to eq(:my_block)
        end.and_return(:my_contract_scope)

        expect(dummy_class.contract { :my_block }).to eq(:my_contract_scope)
      end
    end

    context 'when contract is present and blockless' do
      subject { dummy_class.contract(:my_contract) }

      before do
        allow(Grape::Validations::ContractScope).to receive(:new).with(dummy_class, :my_contract).and_return(:my_contract_scope)
      end

      it { is_expected.to eq(:my_contract_scope) }
    end

    context 'when contract and block are provided' do
      context 'when contract does not respond to schema' do
        let(:my_contract) { Class.new }

        it 'returns a proper rape::Validations::ContractScope' do
          expect(Grape::Validations::ContractScope).to receive(:new).with(dummy_class, my_contract) do |_func, &block|
            expect(block.call).to eq(:my_block)
          end.and_return(:my_contract_scope)

          expect(dummy_class.contract(my_contract.new) { :my_block }).to eq(:my_contract_scope)
        end
      end

      context 'when contract responds to schema' do
        let(:my_contract) do
          Class.new do
            def schema; end
          end
        end

        it 'raises an ArgumentError' do
          expect { dummy_class.contract(my_contract.new) { :my_block } }.to raise_error(ArgumentError, 'Cannot inherit from contract, only schema')
        end
      end
    end
  end
end
