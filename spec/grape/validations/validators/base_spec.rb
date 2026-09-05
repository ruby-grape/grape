# frozen_string_literal: true

describe Grape::Validations::Validators::Base do
  describe '#validate_param!' do
    it 'raises NotImplementedError' do
      scope = Grape::Validations::ParamsScope.new(api: Class.new(Grape::API))
      validator = described_class.new(:id, {}, false, scope, {})
      expect { validator.__send__(:validate_param!, :id, { id: 'value' }) }.to raise_error(NotImplementedError)
    end
  end
end
