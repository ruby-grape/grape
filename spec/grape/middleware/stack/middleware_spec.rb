# frozen_string_literal: true

describe Grape::Middleware::Stack::Middleware do
  let(:middleware_class) { Class.new }
  let(:foo_middleware) { Class.new }
  let(:bar_middleware) { Class.new }

  describe '#==' do
    it 'compares equal to another Middleware wrapping the same class' do
      first = described_class.new(foo_middleware, [], nil)
      second = described_class.new(foo_middleware, [42], proc {})
      expect(first).to eq(second)
    end

    it 'compares unequal to another Middleware wrapping a different class' do
      first = described_class.new(foo_middleware, [], nil)
      second = described_class.new(bar_middleware, [], nil)
      expect(first).not_to eq(second)
    end
  end

  describe '#inspect' do
    it "returns the wrapped class's #to_s" do
      expect(described_class.new(foo_middleware, [], nil).inspect).to eq(foo_middleware.to_s)
    end
  end

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
