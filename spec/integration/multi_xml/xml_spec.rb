# frozen_string_literal: true

describe Grape::Xml, if: defined?(MultiXml) do
  subject { described_class }

  it { is_expected.to eq(::MultiXml) }
end
