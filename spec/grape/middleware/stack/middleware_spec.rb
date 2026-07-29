# frozen_string_literal: true

describe Grape::Middleware::Stack::Middleware do
  let(:middleware_class) { Class.new }

  describe '#hash' do
    it 'matches for two entries wrapping the same class' do
      one = described_class.new(middleware_class, [], nil)
      another = described_class.new(middleware_class, [], nil)
      expect(one.hash).to eq another.hash
    end

    # #== also accepts the wrapped class itself, so it has to hash alike.
    it 'matches the wrapped class' do
      expect(described_class.new(middleware_class, [], nil).hash).to eq middleware_class.hash
    end
  end
end
