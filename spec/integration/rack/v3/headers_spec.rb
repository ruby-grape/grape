# frozen_string_literal: true

describe Grape::Http::Headers do
  it { expect(described_class::ALLOW).to eq('allow') }
  it { expect(described_class::LOCATION).to eq('location') }
  it { expect(described_class::X_CASCADE).to eq('x-cascade') }
end
