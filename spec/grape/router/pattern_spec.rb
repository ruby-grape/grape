# frozen_string_literal: true

RSpec.describe Grape::Router::Pattern do
  describe 'match-parameter readers' do
    subject(:pattern) do
      described_class.new(origin: '/x', suffix: '', anchor: false, params: {}, version: 'v1', requirements: { id: /\d+/ })
    end

    it 'exposes anchor, version and requirements' do
      expect(pattern.anchor).to be(false)
      expect(pattern.version).to eq('v1')
      expect(pattern.requirements).to eq(id: /\d+/)
    end
  end
end
