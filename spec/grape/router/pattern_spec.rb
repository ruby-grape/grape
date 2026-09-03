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

  describe 'version capture' do
    subject(:pattern) do
      described_class.new(origin: '/:version/x', suffix: '', anchor: true, params: {}, version:, requirements: {})
    end

    # The declared versions reach Mustermann as one alternation Regexp, and
    # Regexp.union only accepts Strings and Regexps -- it raises a TypeError on
    # a Symbol or an Integer as soon as there is more than one of them, since a
    # lone entry goes through Regexp.escape instead. `version` accepts both
    # spellings, so they are coerced before the union is built.
    [
      ['Strings',  %w[v1 v2],   %w[v1 v2]],
      ['Symbols',  %i[v1 v2],   %w[v1 v2]],
      ['Integers', [1, 2],      %w[1 2]],
      ['a lone Symbol', :v1,    %w[v1]]
    ].each do |label, declared, expected|
      context "declared as #{label}" do
        let(:version) { declared }

        it 'matches every declared version and nothing else' do
          expected.each { |v| expect(pattern.match?("/#{v}/x")).to be(true) }
          expect(pattern.match?('/v9/x')).to be(false)
        end

        it 'captures the version as a String' do
          expect(pattern.params("/#{expected.first}/x")).to eq('version' => expected.first)
        end
      end
    end
  end

  describe '.build' do
    subject(:pattern) do
      described_class.build(
        path: '/foo',
        namespace: 'ns',
        settings: Grape::Util::InheritableSetting::PathSettings.new(
          mount_path: nil, root_prefix: '/api', format: nil, content_types: nil, version: nil, version_options: nil
        ),
        anchor: true,
        params: {},
        version: nil,
        requirements: {}
      )
    end

    it 'assembles origin/suffix from the path, namespace and settings via Path' do
      expect(pattern.origin).to eq('/api/ns/foo')
      expect(pattern.path).to eq('/api/ns/foo(.:format)')
    end
  end
end
