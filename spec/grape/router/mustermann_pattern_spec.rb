# frozen_string_literal: true

describe Grape::Router::MustermannPattern do
  describe '{name} capture syntax' do
    it 'captures a single path segment' do
      pattern = described_class.new('/foo/{bar}')
      expect(pattern.params('/foo/baz')).to eq('bar' => 'baz')
    end
  end

  describe '{+name} named splat syntax' do
    it 'captures the remainder of the path as a single named value' do
      pattern = described_class.new('/foo/{+bar}')
      expect(pattern.params('/foo/a/b')).to eq('bar' => 'a/b')
    end

    context 'when the named splat is literally called "splat"' do
      it 'captures the remainder of the path as an Array, like the plain splat node' do
        pattern = described_class.new('/foo/{+splat}')
        expect(pattern.params('/foo/a/b')).to eq('splat' => ['a/b'])
      end
    end
  end

  describe ':name capture syntax' do
    context 'when the param is declared as an Integer' do
      it 'only matches digits' do
        pattern = described_class.new('/foo/:bar', params: { 'bar' => { type: 'Integer' } })
        expect(pattern.params('/foo/123')).to eq('bar' => '123')
        expect(pattern).not_to match('/foo/abc')
      end
    end

    context 'when the param is not declared as an Integer' do
      it 'matches any single path segment' do
        pattern = described_class.new('/foo/:bar')
        expect(pattern.params('/foo/abc')).to eq('bar' => 'abc')
      end
    end
  end
end
