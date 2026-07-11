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

  describe '.build' do
    subject(:pattern) do
      described_class.build(path: '/foo', namespace: 'ns', settings: { root_prefix: '/api' }, anchor: true, params: {}, version: nil, requirements: {})
    end

    it 'assembles origin/suffix from the path, namespace and settings via Path' do
      expect(pattern.origin).to eq('/api/ns/foo')
      expect(pattern.path).to eq('/api/ns/foo(.:format)')
    end
  end
end
