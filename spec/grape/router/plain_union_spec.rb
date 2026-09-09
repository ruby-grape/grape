# frozen_string_literal: true

describe Grape::Router::PlainUnion do
  def build_pattern(path, requirements: {}, version: nil)
    Grape::Router::Pattern.new(origin: path, suffix: '', anchor: true, params: {}, version:, requirements:)
  end

  describe '.build' do
    subject(:plain) { described_class.build(union) }

    context 'with a path literal' do
      let(:union) { build_pattern('/resource/:id').to_regexp }

      it 'drops the percent-encoded alternatives' do
        expect(plain.source).not_to include('%')
      end

      it 'still matches the path' do
        expect(plain).to match('/resource/42')
      end

      it 'keeps the named captures the union had' do
        expect(plain.named_captures).to eq(union.named_captures)
      end
    end

    # Mustermann's own `uri_decode: false` compiles a space to a bare `\ `,
    # dropping the `+` branch along with the `%20` one. That would make
    # `/with+space` -- a request carrying no '%' at all, so one resolved here --
    # miss a route the decode-aware union matches.
    context 'with a space in the path' do
      let(:union) { build_pattern('/with space/:id').to_regexp }

      it 'keeps the branch that matches a plus' do
        expect(plain).to match('/with+space/7')
      end

      it 'keeps the branch that matches a literal space' do
        expect(plain).to match('/with space/7')
      end
    end

    # A requirements Regexp can quantify an alternation, and the quantifier
    # binds to the group. Unwrapping a multi-character alternative out of it
    # would rebind the quantifier to that alternative's last character.
    context 'with a quantified multi-character alternation' do
      let(:union) { build_pattern('/resource/:id', requirements: { id: /(?:ab|%41)+/ }).to_regexp }

      it 'keeps the group around the surviving alternative' do
        expect(plain.source).to include('(?:ab)+')
      end

      it 'still matches a repetition of the whole alternative' do
        expect(plain).to match('/resource/abab')
      end

      it 'does not start matching a repetition of its last character' do
        expect(plain).not_to match('/resource/abb')
      end
    end

    context 'with an escaped bar in the path' do
      let(:union) { build_pattern('/a\\|b/:id').to_regexp }

      it 'does not cut the escape in half' do
        expect(plain).to match('/a|b/7')
      end
    end

    context 'with declared versions' do
      let(:union) { build_pattern('/:version/resource', version: %w[v1 v2]).to_regexp }

      it 'leaves the versions alternation alone' do
        expect(plain.source).to include('v1|v2')
      end
    end

    context 'when there is nothing to strip' do
      let(:union) { build_pattern('/:id').to_regexp }

      it 'returns the union itself' do
        expect(plain).to be(union)
      end
    end

    # A requirements Regexp is inserted into the pattern verbatim, so it can
    # carry a character class holding the very characters the rewrite looks for.
    # Inside a class they are literals, and dropping them would shrink the set
    # the route matches.
    context 'with a requirements Regexp whose character class looks like an alternation' do
      let(:union) { build_pattern('/resource/:id', requirements: { id: /[(?:a|%41)]+/ }).to_regexp }

      it 'leaves the character class untouched' do
        expect(plain.source).to include('[(?:a|%41)]')
      end

      it 'still matches every character of the class' do
        expect(plain).to match('/resource/|4')
      end
    end

    context 'when the rewritten source would not compile' do
      let(:union) { build_pattern('/resource/:id').to_regexp }

      before { allow(described_class).to receive(:strip_percent_alternatives).and_return('(') }

      it 'falls back to the union' do
        expect(plain).to be(union)
      end
    end

    context 'when the rewritten source would renumber the captures' do
      let(:union) { build_pattern('/resource/:id').to_regexp }

      before { allow(described_class).to receive(:strip_percent_alternatives).and_return('(?<other>x)') }

      it 'falls back to the union' do
        expect(plain).to be(union)
      end
    end
  end
end
