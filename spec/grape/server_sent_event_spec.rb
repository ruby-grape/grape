# frozen_string_literal: true

describe Grape::ServerSentEvent do
  it 'leaves out every field not given' do
    expect(described_class.new(data: 'x')).to have_attributes(data: 'x', event: nil, id: nil, retry: nil, comment: nil)
  end

  it 'takes a Symbol event and an Integer id' do
    expect(described_class.new(event: :token, id: 7)).to have_attributes(event: :token, id: 7)
  end

  it 'takes a comment that spans lines' do
    expect(described_class.new(comment: "a\nb").comment).to eq("a\nb")
  end

  ["a\nb", "a\rb", "a\r\nb"].each do |value|
    it "rejects an event of #{value.inspect}" do
      expect { described_class.new(event: value) }.to raise_error(ArgumentError, /event must be one line/)
    end

    it "rejects an id of #{value.inspect}" do
      expect { described_class.new(id: value) }.to raise_error(ArgumentError, /id must be one line without NUL/)
    end
  end

  it 'rejects an id holding NUL, which the client ignores' do
    expect { described_class.new(id: "a\0b") }.to raise_error(ArgumentError, /id must be one line without NUL/)
  end

  [-1, 1.5, '1000'].each do |value|
    it "rejects a retry of #{value.inspect}" do
      expect { described_class.new(retry: value) }.to raise_error(ArgumentError, /retry must be a non-negative Integer/)
    end
  end

  it 'takes a retry of 0' do
    expect(described_class.new(retry: 0).retry).to eq(0)
  end
end
