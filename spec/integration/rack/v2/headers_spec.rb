# frozen_string_literal: true

describe Grape::Http::Headers, if: Gem::Version.new(Rack.release) < Gem::Version.new('3') do
  it { expect(described_class::ALLOW).to eq('Allow') }
  it { expect(described_class::LOCATION).to eq('Location') }
  it { expect(described_class::TRANSFER_ENCODING).to eq('Transfer-Encoding') }
  it { expect(described_class::X_CASCADE).to eq('X-Cascade') }
end
