# frozen_string_literal: true

describe Grape::Http::Headers do
  it { expect(described_class::CONTENT_TYPE).to eq('Content-Type') }
  it { expect(described_class::X_CASCADE).to eq('X-Cascade') }
end
