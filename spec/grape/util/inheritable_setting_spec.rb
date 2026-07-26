# frozen_string_literal: true

describe Grape::Util::InheritableSetting do
  before do
    described_class.reset_global!
    subject.inherit_from parent
  end

  let(:parent) do
    described_class.new.tap do |settings|
      settings.global[:global_thing] = :global_foo_bar
      settings.namespace[:namespace_thing] = :namespace_foo_bar
      settings.root_prefix = :namespace_inheritable_foo_bar
      settings.add_helper(:namespace_stackable_foo_bar)
      settings.route[:route_thing] = :route_foo_bar
    end
  end

  let(:other_parent) do
    described_class.new.tap do |settings|
      settings.namespace[:namespace_thing] = :namespace_foo_bar_other
      settings.root_prefix = :namespace_inheritable_foo_bar_other
      settings.add_helper(:namespace_stackable_foo_bar_other)
      settings.route[:route_thing] = :route_foo_bar_other
    end
  end

  describe '#global' do
    it 'sets a global value' do
      subject.global[:some_thing] = :foo_bar
      expect(subject.global[:some_thing]).to eq :foo_bar
      subject.global[:some_thing] = :foo_bar_next
      expect(subject.global[:some_thing]).to eq :foo_bar_next
    end

    it 'sets the global inherited values' do
      expect(subject.global[:global_thing]).to eq :global_foo_bar
    end

    it 'overrides global values' do
      subject.global[:global_thing] = :global_new_foo_bar
      expect(parent.global[:global_thing]).to eq :global_new_foo_bar
    end

    it 'handles different parents' do
      subject.global[:global_thing] = :global_new_foo_bar

      subject.inherit_from other_parent

      expect(parent.global[:global_thing]).to eq :global_new_foo_bar
      expect(other_parent.global[:global_thing]).to eq :global_new_foo_bar
    end
  end

  describe '#namespace' do
    it 'sets a value until the end of a namespace' do
      subject.namespace[:some_thing] = :foo_bar
      expect(subject.namespace[:some_thing]).to eq :foo_bar
    end

    it 'uses new values when a new namespace starts' do
      subject.namespace[:namespace_thing] = :new_namespace_foo_bar
      expect(subject.namespace[:namespace_thing]).to eq :new_namespace_foo_bar

      expect(parent.namespace[:namespace_thing]).to eq :namespace_foo_bar
    end
  end

  describe '#namespace_inheritable' do
    it 'works with inheritable values' do
      expect(subject.root_prefix).to eq :namespace_inheritable_foo_bar
    end

    it 'handles different parents' do
      expect(subject.root_prefix).to eq :namespace_inheritable_foo_bar

      subject.inherit_from other_parent

      expect(subject.root_prefix).to eq :namespace_inheritable_foo_bar_other

      subject.inherit_from parent

      expect(subject.root_prefix).to eq :namespace_inheritable_foo_bar

      subject.inherit_from other_parent

      subject.root_prefix = :my_thing

      expect(subject.root_prefix).to eq :my_thing

      subject.inherit_from parent

      expect(subject.root_prefix).to eq :my_thing
    end
  end

  describe '#namespace_stackable' do
    it 'works with stackable values' do
      expect(subject.helpers).to eq [:namespace_stackable_foo_bar]

      subject.inherit_from other_parent

      expect(subject.helpers).to eq [:namespace_stackable_foo_bar_other]
    end
  end

  describe '#rescue_handlers / #add_rescue_handlers' do
    it 'records subclass-matching handlers under rescue_handlers' do
      subject.add_rescue_handlers({ StandardError => :handler }, subclasses: true)
      expect(subject.rescue_handlers).to eq(StandardError => :handler)
      expect(subject.base_only_rescue_handlers).to be_nil
    end

    it 'records exact-match handlers under base_only_rescue_handlers' do
      subject.add_rescue_handlers({ StandardError => :handler }, subclasses: false)
      expect(subject.base_only_rescue_handlers).to eq(StandardError => :handler)
      expect(subject.rescue_handlers).to be_nil
    end

    it 'lets a nested scope override an inherited handler for the same class' do
      parent = described_class.new.tap { |s| s.add_rescue_handlers({ StandardError => :parent }, subclasses: true) }
      subject.inherit_from parent
      subject.add_rescue_handlers({ StandardError => :child }, subclasses: true)
      expect(subject.rescue_handlers).to eq(StandardError => :child)
    end
  end

  describe '#route' do
    it 'sets a value until the next route' do
      subject.route[:some_thing] = :foo_bar
      expect(subject.route[:some_thing]).to eq :foo_bar

      subject.route_end

      expect(subject.route[:some_thing]).to be_nil
    end

    it 'works with route values' do
      expect(subject.route[:route_thing]).to eq :route_foo_bar
    end
  end

  describe 'route-scope accessors' do
    it 'reads and writes the per-route validation snapshot' do
      subject.route_validations = [:validator]
      expect(subject.route_validations).to eq [:validator]
    end

    it 'reads and writes the per-route declared-params snapshot' do
      subject.route_declared_params = [:id]
      expect(subject.route_declared_params).to eq [:id]
    end

    it 'defaults renamed params to an empty hash and accumulates additions' do
      expect(subject.route_renamed_params).to eq({})

      subject.add_route_renamed_param(['a'], 'b')
      subject.add_route_renamed_param(['c'], 'd')
      expect(subject.route_renamed_params).to eq({ ['a'] => 'b', ['c'] => 'd' })
    end

    it 'defaults the description to an empty hash and round-trips writes' do
      expect(subject.route_description).to eq({})

      subject.route_description = { description: 'x' }
      expect(subject.route_description).to eq({ description: 'x' })
    end

    it 'exposes route settings without the internal param snapshots' do
      subject.route_end
      subject.route_validations = [:validator]
      subject.route_declared_params = [:id]
      subject.route_description = { description: 'x' }
      subject.route[:custom] = :value

      expect(subject.route_settings).to eq(description: { description: 'x' }, custom: :value)
    end

    it 'reads and writes arbitrary route settings' do
      expect(subject.route_setting(:custom)).to be_nil

      subject.route_setting(:custom, :value)
      expect(subject.route_setting(:custom)).to eq :value
    end
  end

  describe '#inherit_from' do
    it 'notifies clones' do
      new_settings = subject.point_in_time_copy
      expect(new_settings).to receive(:inherit_from).with(other_parent)

      subject.inherit_from other_parent
    end
  end

  describe '#point_in_time_copy' do
    let!(:cloned_obj) { subject.point_in_time_copy }

    it 'does not carry over the list of registered clones' do
      expect(cloned_obj.instance_variable_get(:@point_in_time_copies)).to be_nil
    end

    it 'decouples namespace values' do
      subject.namespace[:namespace_thing] = :namespace_foo_bar

      cloned_obj.namespace[:namespace_thing] = :new_namespace_foo_bar
      expect(subject.namespace[:namespace_thing]).to eq :namespace_foo_bar
    end

    it 'decouples namespace inheritable values' do
      expect(cloned_obj.root_prefix).to eq :namespace_inheritable_foo_bar

      subject.root_prefix = :my_thing
      expect(subject.root_prefix).to eq :my_thing

      expect(cloned_obj.root_prefix).to eq :namespace_inheritable_foo_bar

      cloned_obj.root_prefix = :my_cloned_thing
      expect(cloned_obj.root_prefix).to eq :my_cloned_thing
      expect(subject.root_prefix).to eq :my_thing
    end

    it 'decouples namespace stackable values' do
      expect(cloned_obj.helpers).to eq [:namespace_stackable_foo_bar]

      subject.add_helper(:other_thing)
      expect(subject.helpers).to eq %i[namespace_stackable_foo_bar other_thing]
      expect(cloned_obj.helpers).to eq [:namespace_stackable_foo_bar]
    end

    it 'decouples route values' do
      expect(cloned_obj.route[:route_thing]).to eq :route_foo_bar

      subject.route[:route_thing] = :new_route_foo_bar
      expect(cloned_obj.route[:route_thing]).to eq :route_foo_bar
    end

    it 'adds itself to original as clone' do
      expect(subject.instance_variable_get(:@point_in_time_copies)).to include(cloned_obj)
    end
  end

  describe '#to_hash' do
    it 'return all settings as a hash' do
      subject.global[:global_thing] = :global_foo_bar
      subject.namespace[:namespace_thing] = :namespace_foo_bar
      subject.root_prefix = :namespace_inheritable_foo_bar
      subject.add_helper([:namespace_stackable_foo_bar])
      subject.add_rescue_handlers({ StandardError => :handler }, subclasses: true)
      subject.route[:route_thing] = :route_foo_bar
      expect(subject.to_hash).to match(
        global: { global_thing: :global_foo_bar },
        namespace: { namespace_thing: :namespace_foo_bar },
        namespace_inheritable: {
          root_prefix: :namespace_inheritable_foo_bar
        },
        namespace_stackable: { helpers: [:namespace_stackable_foo_bar, [:namespace_stackable_foo_bar]] },
        rescue_handlers: { StandardError => :handler },
        base_only_rescue_handlers: nil,
        route: { route_thing: :route_foo_bar }
      )
    end
  end
end
