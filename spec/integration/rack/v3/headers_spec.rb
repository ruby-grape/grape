# frozen_string_literal: true

describe Grape::Http::Headers do
  it { expect(described_class::CONTENT_TYPE).to eq('content-type') }
  it { expect(described_class::X_CASCADE).to eq('x-cascade') }
end
