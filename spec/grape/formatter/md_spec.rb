# frozen_string_literal: true

describe Grape::Formatter::Md do
  it 'is registered under :md' do
    expect(Grape::Formatter.formatter_for(:md, nil)).to be(described_class)
  end

  describe '.call' do
    it 'calls #to_markdown when the object responds to it' do
      page = Class.new do
        def to_markdown
          "# Hello\n"
        end
      end.new
      expect(described_class.call(page, {})).to eq("# Hello\n")
    end

    it 'returns a String as is' do
      expect(described_class.call('# Hello', {})).to eq('# Hello')
    end

    it 'raises Grape::Exceptions::InvalidFormatter for any other object' do
      expect { described_class.call({ a: 1 }, {}) }.to raise_error(Grape::Exceptions::InvalidFormatter, 'cannot convert Hash to md')
    end
  end
end
