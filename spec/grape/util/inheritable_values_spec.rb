# frozen_string_literal: true

describe Grape::Util::InheritableValues do
  subject { described_class.new(parent) }

  let(:parent) { described_class.new }

  describe '#delete' do
    it 'deletes a key' do
      subject[:some_thing] = :new_foo_bar
      subject.delete :some_thing
      expect(subject[:some_thing]).to be_nil
    end

    it 'does not delete parent values' do
      parent[:some_thing] = :foo
      subject[:some_thing] = :new_foo_bar
      subject.delete :some_thing
      expect(subject[:some_thing]).to eq :foo
    end
  end

  describe '#[]' do
    it 'returns a value' do
      subject[:some_thing] = :foo
      expect(subject[:some_thing]).to eq :foo
    end

    it 'returns parent value when no value is set' do
      parent[:some_thing] = :foo
      expect(subject[:some_thing]).to eq :foo
    end

    it 'overwrites parent value with the current one' do
      parent[:some_thing] = :foo
      subject[:some_thing] = :foo_bar
      expect(subject[:some_thing]).to eq :foo_bar
    end

    it 'parent values are not changed' do
      parent[:some_thing] = :foo
      subject[:some_thing] = :foo_bar
      expect(parent[:some_thing]).to eq :foo
    end
  end

  describe '#[]=' do
    it 'sets a value' do
      subject[:some_thing] = :foo
      expect(subject[:some_thing]).to eq :foo
    end
  end

  describe '#to_hash' do
    it 'returns a Hash representation' do
      parent[:some_thing] = :foo
      subject[:some_thing_more] = :foo_bar
      expect(subject.to_hash).to eq(some_thing: :foo, some_thing_more: :foo_bar)
    end
  end

  describe '#==' do
    it 'is true for two layers over the same parent with the same overrides' do
      subject[:some_thing] = :foo
      expect(subject).to eq(described_class.new(parent).tap { |v| v[:some_thing] = :foo })
    end

    it 'is false when the overrides differ' do
      subject[:some_thing] = :foo
      expect(subject).not_to eq(described_class.new(parent).tap { |v| v[:some_thing] = :bar })
    end

    it 'is false when the inherited values differ' do
      parent[:some_thing] = :foo
      expect(subject).not_to eq(described_class.new(described_class.new))
    end

    it 'does not distinguish a never-written layer from one emptied by #delete' do
      subject[:some_thing] = :foo
      subject.delete :some_thing
      expect(subject).to eq(described_class.new(parent))
    end

    it 'is true when an override only restates an inherited value' do
      parent[:some_thing] = :foo
      subject[:some_thing] = :foo
      expect(subject).to eq(described_class.new(parent))
    end

    it 'is false for a non-InheritableValues' do
      expect(subject).not_to eq(subject.to_hash)
    end
  end

  describe '#clone' do
    let(:obj_cloned) { subject.clone }

    context 'complex (i.e. not primitive) data types (ex. entity classes, please see bug #891)' do
      let(:description) { { entity: double } }

      before { subject[:description] = description }

      it 'copies values; does not duplicate them' do
        expect(obj_cloned[:description]).to eq description
      end
    end
  end
end
