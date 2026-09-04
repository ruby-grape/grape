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

  # A requirement is handed to Mustermann as the capture's constraint. Given a
  # Regexp it only narrows what the route matches, but a Class or a Symbol
  # Mustermann knows also registers a *converter*, so the value the router
  # extracts is no longer a String.
  describe 'capture types in requirements' do
    subject(:pattern) do
      described_class.new(origin: '/:id', suffix: '', anchor: true, params: {}, version: nil, requirements: { id: requirement })
    end

    context 'when the requirement is a Regexp' do
      let(:requirement) { /\d+/ }

      it 'narrows the match and leaves the value a String' do
        expect(pattern.match?('/abc')).to be(false)
        expect(pattern.params('/42')).to include('id' => '42')
      end
    end

    [
      [Integer, '/42', 42],
      [Float, '/4.2', 4.2],
      [Symbol, '/abc', :abc],
      [:integer, '/42', 42],
      [:date, '/2020-01-02', Date.new(2020, 1, 2)],
      [:version, '/1.2.3', Gem::Version.new('1.2.3')]
    ].each do |requirement, input, expected|
      context "when the requirement is #{requirement.inspect}" do
        let(:requirement) { requirement }

        it 'converts the captured value' do
          expect(pattern.params(input)).to include('id' => expected)
        end
      end
    end

    context 'when the requirement is a type that only narrows the match' do
      let(:requirement) { :uuid }

      it 'leaves the value a String' do
        expect(pattern.match?('/nope')).to be(false)
        expect(pattern.params('/123e4567-e89b-12d3-a456-426614174000')).to include('id' => '123e4567-e89b-12d3-a456-426614174000')
      end
    end

    context 'when the requirement names no capture type Mustermann knows' do
      let(:requirement) { Object }

      it 'raises when the pattern is built' do
        expect { pattern }.to raise_error(Mustermann::CompileError, /no converter for class Object/)
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
