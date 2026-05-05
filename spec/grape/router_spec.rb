# frozen_string_literal: true

describe Grape::Router do
  describe '.normalize_path' do
    it 'is deprecated and delegates to Grape::Util::PathNormalizer' do
      expect { described_class.normalize_path('/foo/') }.to raise_error(
        ActiveSupport::DeprecationException, /Grape::Util::PathNormalizer/
      )
    end
  end
end
