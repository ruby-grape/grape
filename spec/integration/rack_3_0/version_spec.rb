# frozen_string_literal: true

describe Rack do
  it { expect(Gem::Version.new(described_class.release).segments.first).to eq 3 }
end
