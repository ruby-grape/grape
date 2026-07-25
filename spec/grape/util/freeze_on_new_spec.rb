# frozen_string_literal: true

RSpec.describe Grape::Util::FreezeOnNew do
  let(:base) do
    Class.new do
      extend Grape::Util::FreezeOnNew

      attr_reader :a

      def initialize
        @a = 1
      end
    end
  end

  it 'returns frozen instances from new' do
    expect(base.new).to be_frozen
  end

  it 'covers subclasses through singleton-class inheritance' do
    expect(Class.new(base).new).to be_frozen
  end

  it 'freezes only after the whole initialize chain, so subclasses may assign ivars after super' do
    subclass = Class.new(base) do
      attr_reader :b

      def initialize
        super
        @b = 2
      end
    end

    instance = subclass.new
    expect(instance).to be_frozen
    expect(instance.a).to eq(1)
    expect(instance.b).to eq(2)
  end
end
