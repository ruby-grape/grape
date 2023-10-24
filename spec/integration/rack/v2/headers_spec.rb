# frozen_string_literal: true

describe Grape::Http::Headers do
  it { expect(described_class::ALLOW).to eq('Allow') }
  it { expect(described_class::LOCATION).to eq('Location') }
  it { expect(described_class::X_CASCADE).to eq('X-Cascade') }
end
