# frozen_string_literal: true

describe Grape::Util::StackableValues do
  subject { described_class.new(new_values, parent) }

  let(:parent_values) { {} }
  let(:new_values) { {} }
  let(:parent) { described_class.new(parent_values, {}) }

  describe '#keys' do
    it 'returns all keys' do
      new_values[:some_thing] = [:foo_bar]
      new_values[:some_thing_else] = [:foo_bar]
      expect(subject.keys).to eq %i[some_thing some_thing_else]
    end

    it 'returns merged keys with parent' do
      parent_values[:some_thing] = [:foo]
      parent_values[:some_thing_else] = [:foo]

      new_values[:some_thing] = [:foo_bar]
      new_values[:some_thing_more] = [:foo_bar]

      expect(subject.keys).to eq %i[some_thing some_thing_else some_thing_more]
    end
  end

  describe '#[]' do
    it 'returns an array of values' do
      new_values[:some_thing] = [:foo]
      expect(subject[:some_thing]).to eq [:foo]
    end

    it 'returns a frozen empty array when nothing is registered' do
      expect(subject[:some_thing]).to eq []
      expect(subject[:some_thing]).to be_frozen
    end

    it 'returns parent value when no value is set' do
      parent_values[:some_thing] = [:foo]
      expect(subject[:some_thing]).to eq [:foo]
    end

    it 'combines parent and actual values, outermost scope first' do
      parent_values[:some_thing] = [:foo]
      new_values[:some_thing] = [:foo_bar]
      expect(subject[:some_thing]).to eq %i[foo foo_bar]
    end

    it 'does not change parent values' do
      parent_values[:some_thing] = [:foo]
      new_values[:some_thing] = [:foo_bar]
      expect(parent[:some_thing]).to eq [:foo]
    end
  end

  describe '#to_hash' do
    it 'returns a Hash representation' do
      parent_values[:some_thing] = [:foo]
      new_values[:some_thing] = [%i[bar more]]
      new_values[:some_thing_more] = [:foo_bar]
      expect(subject.to_hash).to eq(some_thing: [:foo, %i[bar more]], some_thing_more: [:foo_bar])
    end
  end

  describe 'the view built by Grape::Util::InheritableSetting' do
    let(:root) { Grape::Util::InheritableSetting.new }
    let(:child) { Grape::Util::InheritableSetting.new.tap { |setting| setting.inherit_from(root) } }

    it 'exposes each scope own registrations through #new_values' do
      root.add_helper(:outer)
      child.add_helper(:inner)

      expect(child.namespace_stackable.new_values).to eq(helpers: [:inner])
      expect(child.namespace_stackable.inherited_values.new_values).to eq(helpers: [:outer])
    end

    it 'leaves #new_values nil for a scope which registered nothing' do
      expect(child.namespace_stackable.new_values).to be_nil
    end

    it 'terminates the inherited_values chain at the root scope' do
      views = []
      view = child.namespace_stackable
      while view.is_a?(described_class)
        views << view
        view = view.inherited_values
      end

      expect(views.size).to eq 2
      expect(view).to eq({})
    end

    it 'reads registrations across the chain, outermost scope first' do
      root.add_helper(:outer)
      child.add_helper(:inner)

      expect(child.namespace_stackable[:helpers]).to eq %i[outer inner]
    end

    it 'is a view rather than the store, so writes to it register nothing' do
      child.namespace_stackable.new_values&.[]=(:helpers, [:ignored])

      expect(child.helpers).to eq []
    end
  end
end
