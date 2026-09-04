# frozen_string_literal: true

describe Grape::Validations::AttributesIterator do
  describe '#yield_attributes' do
    it 'raises NotImplementedError' do
      scope = instance_double(Grape::Validations::ParamsScope, array_depth: 0)
      iterator = described_class.new([], scope)
      expect { iterator.__send__(:yield_attributes, {}) }.to raise_error(NotImplementedError)
    end
  end
end
