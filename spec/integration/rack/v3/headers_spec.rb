# frozen_string_literal: true

describe Grape::Http::Headers do
  it { expect(described_class::ALLOW).to eq('allow') }
  it { expect(described_class::CACHE_CONTROL).to eq('cache-control') }
  it { expect(described_class::CONTENT_LENGTH).to eq('content-length') }
  it { expect(described_class::CONTENT_TYPE).to eq('content-type') }
  it { expect(described_class::LOCATION).to eq('location') }
  it { expect(described_class::TRANSFER_ENCODING).to eq('transfer-encoding') }
  it { expect(described_class::X_CASCADE).to eq('x-cascade') }
end
