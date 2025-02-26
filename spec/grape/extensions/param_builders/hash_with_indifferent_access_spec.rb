# frozen_string_literal: true

describe Grape::Extensions::ActiveSupport::HashWithIndifferentAccess::ParamBuilder do
  describe 'deprecation' do
    context 'when included' do
      subject do
        Class.new(Grape::API) do
          include Grape::Extensions::ActiveSupport::HashWithIndifferentAccess::ParamBuilder
        end
      end

      let(:message) do
        'This concern has been deprecated. Use `build_with` with one of the following short_name (:hash, :hash_with_indifferent_access, :hashie_mash) instead.'
      end

      it 'raises a deprecation' do
        expect(Grape.deprecator).to receive(:warn).with(message).and_raise(ActiveSupport::DeprecationException, :deprecated)
        expect { subject }.to raise_error(ActiveSupport::DeprecationException, 'deprecated')
      end
    end
  end

  context 'when using class name' do
    let(:app) do
      Class.new(Grape::API) do
        params do
          build_with Grape::Extensions::ActiveSupport::HashWithIndifferentAccess::ParamBuilder
        end
        get
      end
    end

    it 'raises a deprecation' do
      expect(Grape.deprecator).to receive(:warn).with("#{described_class} has been deprecated. Use short name :hash_with_indifferent_access instead.").and_raise(ActiveSupport::DeprecationException, :deprecated)
      expect { get '/' }.to raise_error(ActiveSupport::DeprecationException, 'deprecated')
    end
  end
end
