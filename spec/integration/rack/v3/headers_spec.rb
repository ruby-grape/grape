# frozen_string_literal: true

describe Grape::Http::Headers, if: Gem::Version.new(Rack.release) >= Gem::Version.new('3') do
  it { expect(described_class::ALLOW).to eq('allow') }
  it { expect(described_class::LOCATION).to eq('location') }
  it { expect(described_class::TRANSFER_ENCODING).to eq('transfer-encoding') }
  it { expect(described_class::X_CASCADE).to eq('x-cascade') }
end
