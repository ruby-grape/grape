# frozen_string_literal: true

describe Grape::Http::Headers do
  it { expect(described_class::ALLOW).to eq('Allow') }
  it { expect(described_class::CACHE_CONTROL).to eq('Cache-Control') }
  it { expect(described_class::CONTENT_LENGTH).to eq('Content-Length') }
  it { expect(described_class::CONTENT_TYPE).to eq('Content-Type') }
  it { expect(described_class::LOCATION).to eq('Location') }
  it { expect(described_class::TRANSFER_ENCODING).to eq('Transfer-Encoding') }
  it { expect(described_class::X_CASCADE).to eq('X-Cascade') }
end
