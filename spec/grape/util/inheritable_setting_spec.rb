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

  describe '#hash' do
    it 'matches for two copies forked from the same scope' do
      sibling = subject.point_in_time_copy
      expect(subject.point_in_time_copy.hash).to eq sibling.hash
    end

    # #== accepts two instances whose own stores differ as long as their
    # chains resolve alike, so #hash has to key on the resolved state.
    it 'matches when different chains resolve to the same values' do
      parent = described_class.new
      parent.add_helper(:shared)
      inherits = described_class.new.tap { |setting| setting.inherit_from(parent) }

      standalone = described_class.new
      standalone.add_helper(:shared)

      expect(inherits).to eq standalone
      expect(inherits.hash).to eq standalone.hash
      expect(Set.new([inherits, standalone]).size).to eq 1
    end
  end

  describe '#==' do
    # Endpoint settings are forked as siblings sharing one parent, so this is
    # the shape the duplicate-route check in DSL::Routing#route compares.
    let(:sibling) { subject.point_in_time_copy }

    it 'is true for two copies forked from the same scope' do
      expect(subject.point_in_time_copy).to eq sibling
    end

    it 'is false when only one copy registered a namespace' do
      sibling.add_namespace(Grape::Namespace.new(:foo))
      expect(subject.point_in_time_copy).not_to eq sibling
    end

    it 'is false when the route settings differ' do
      sibling.route_setting(:description, foo: :bar)
      expect(subject.point_in_time_copy).not_to eq sibling
    end

    it 'is false when an inheritable value differs' do
      sibling.default_error_status = 404
      expect(subject.point_in_time_copy).not_to eq sibling
    end

    it 'is false when a rescue handler differs' do
      sibling.add_rescue_handlers({ StandardError => :handler }, subclasses: true)
      expect(subject.point_in_time_copy).not_to eq sibling
    end

    it 'still compares copies that hang off different parents' do
      other = described_class.new
      other.inherit_from other_parent
      expect(subject.point_in_time_copy).not_to eq other.point_in_time_copy
    end

    it 'is false for a non-InheritableSetting' do
      expect(subject).not_to eq subject.to_hash
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

  describe 'inheritable value resolution' do
    it 'shadows an inherited value with an explicitly assigned nil' do
      parent.cascade = true
      subject.cascade = nil

      expect(subject.cascade).to be_nil
      expect(parent.cascade).to be(true)
    end

    it 'reports through the predicate that an enclosing scope assigned a value' do
      expect(subject.cascade_defined?).to be(false)

      parent.cascade = false

      expect(subject.cascade_defined?).to be(true)
      expect(subject.cascade).to be(false)
    end

    it 'resolves a value the parent gains after the child was created' do
      expect(subject.auth).to be_nil

      parent.auth = { type: :http_basic }

      expect(subject.auth).to eq(type: :http_basic)
    end

    it 'leaves the parent untouched when a nested scope overrides' do
      subject.root_prefix = :child_prefix

      expect(parent.root_prefix).to eq :namespace_inheritable_foo_bar
    end

    # See bug #891: entity classes and the like are shared with a copy, never
    # duplicated.
    it 'shares complex values with a point-in-time copy rather than duplicating them' do
      options = { entity: Class.new }
      subject.version_options = options

      expect(subject.point_in_time_copy.version_options).to be(options)
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

    # The case above registers only on the parent, so the copy never shares an
    # Array with `subject` and passes even when the per-key Arrays are shared.
    # Here the key already holds one of `subject`'s own registrations when the
    # copy is taken, which is what made the later one leak into it.
    context 'when the scope already registered the key itself' do
      subject(:setting) do
        described_class.new.tap do |settings|
          settings.inherit_from parent
          settings.add_helper(:own_before_copy)
        end
      end

      let!(:cloned_obj) { setting.point_in_time_copy }

      it 'does not leak a later registration into the copy' do
        setting.add_helper(:own_after_copy)

        expect(setting.helpers).to eq %i[namespace_stackable_foo_bar own_before_copy own_after_copy]
        expect(cloned_obj.helpers).to eq %i[namespace_stackable_foo_bar own_before_copy]
      end

      it 'does not leak the copy’s own registration back to the source' do
        cloned_obj.add_helper(:only_on_copy)

        expect(setting.helpers).to eq %i[namespace_stackable_foo_bar own_before_copy]
        expect(cloned_obj.helpers).to eq %i[namespace_stackable_foo_bar own_before_copy only_on_copy]
      end

      it 'keeps sibling copies independent' do
        sibling = setting.point_in_time_copy
        cloned_obj.add_helper(:only_on_first)

        expect(sibling.helpers).to eq %i[namespace_stackable_foo_bar own_before_copy]
      end
    end

    # Same shape as the stackable case: the per-kind Hashes inside
    # @rescue_handler_maps have to be duped, not just the Hash holding them.
    context 'when the scope already registered a rescue handler' do
      subject(:setting) do
        described_class.new.tap do |settings|
          settings.add_rescue_handlers({ ArgumentError => :before_copy }, subclasses: true)
        end
      end

      let!(:cloned_obj) { setting.point_in_time_copy }

      it 'does not leak a later handler into the copy' do
        setting.add_rescue_handlers({ TypeError => :after_copy }, subclasses: true)

        expect(setting.rescue_handlers).to eq(ArgumentError => :before_copy, TypeError => :after_copy)
        expect(cloned_obj.rescue_handlers).to eq(ArgumentError => :before_copy)
      end

      it 'does not leak a later base-only handler into the copy' do
        setting.add_rescue_handlers({ TypeError => :after_copy }, subclasses: false)

        expect(setting.base_only_rescue_handlers).to eq(TypeError => :after_copy)
        expect(cloned_obj.base_only_rescue_handlers).to be_blank
      end
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
