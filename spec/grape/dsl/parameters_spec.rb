# frozen_string_literal: true

describe Grape::DSL::Parameters do
  subject { dummy_class.new }

  let(:dummy_class) do
    Class.new do
      include Grape::DSL::Parameters
      attr_accessor :api, :element, :parent

      def initialize
        @validate_attributes = []
      end

      def validate_attributes(*args)
        @validate_attributes.push(*args)
      end

      def validate_attributes_reader
        @validate_attributes
      end

      def push_declared_params(args, _opts)
        @push_declared_params = args
      end

      def push_declared_params_reader
        @push_declared_params
      end

      def validates(*args)
        @validates = *args
      end

      def validates_reader
        @validates
      end

      def new_scope(args, _, &block)
        nested_scope = self.class.new
        nested_scope.new_group_scope(args, &block)
        nested_scope
      end

      def new_group_scope(args)
        prev_group = @group
        @group = args.clone.first
        yield
        @group = prev_group
      end

      def extract_message_option(attrs)
        return nil unless attrs.is_a?(Array)

        opts = attrs.last.is_a?(Hash) ? attrs.pop : {}
        opts.key?(:message) && !opts[:message].nil? ? opts.delete(:message) : nil
      end
    end
  end

  describe '#use' do
    before do
      allow_message_expectations_on_nil
      allow(subject.api).to receive(:namespace_stackable).with(:named_params)
    end

    let(:options) { { option: 'value' } }
    let(:named_params) { { params_group: proc {} } }

    it 'calls processes associated with named params' do
      allow(subject.api).to receive(:namespace_stackable_with_hash).and_return(named_params)
      expect(subject).to receive(:instance_exec).with(options).and_yield
      subject.use :params_group, options
    end

    it 'raises error when non-existent named param is called' do
      allow(subject.api).to receive(:namespace_stackable_with_hash).and_return({})
      expect { subject.use :params_group }.to raise_error('Params :params_group not found!')
    end
  end

  describe '#use_scope' do
    it 'is alias to #use' do
      expect(subject.method(:use_scope)).to eq subject.method(:use)
    end
  end

  describe '#includes' do
    it 'is alias to #use' do
      expect(subject.method(:includes)).to eq subject.method(:use)
    end
  end

  describe '#requires' do
    it 'adds a required parameter' do
      subject.requires :id, type: Integer, desc: 'Identity.'

      expect(subject.validate_attributes_reader).to eq([[:id], { type: Integer, desc: 'Identity.', presence: { value: true, message: nil } }])
      expect(subject.push_declared_params_reader).to eq([:id])
    end
  end

  describe '#optional' do
    it 'adds an optional parameter' do
      subject.optional :id, type: Integer, desc: 'Identity.'

      expect(subject.validate_attributes_reader).to eq([[:id], { type: Integer, desc: 'Identity.' }])
      expect(subject.push_declared_params_reader).to eq([:id])
    end
  end

  describe '#with' do
    it 'creates a scope with group attributes' do
      subject.with(type: Integer) { subject.optional :id, desc: 'Identity.' }

      expect(subject.validate_attributes_reader).to eq([[:id], { type: Integer, desc: 'Identity.' }])
      expect(subject.push_declared_params_reader).to eq([:id])
    end

    it 'merges the group attributes' do
      subject.with(documentation: { in: 'body' }) { subject.optional :vault, documentation: { default: 33 } }

      expect(subject.validate_attributes_reader).to eq([[:vault], { documentation: { in: 'body', default: 33 } }])
      expect(subject.push_declared_params_reader).to eq([:vault])
    end

    it 'overrides the group attribute when values not mergable' do
      subject.with(type: Integer, documentation: { in: 'body', default: 33 }) do
        subject.optional :vault
        subject.optional :allowed_vaults, type: [Integer], documentation: { default: [31, 32, 33], is_array: true }
      end

      expect(subject.validate_attributes_reader).to eq(
        [
          [:vault], { type: Integer, documentation: { in: 'body', default: 33 } },
          [:allowed_vaults], { type: [Integer], documentation: { in: 'body', default: [31, 32, 33], is_array: true } }
        ]
      )
    end

    it 'allows a primitive type attribite to overwrite a complex type group attribute' do
      subject.with(documentation: { x: { nullable: true } }) do
        subject.optional :vault, type: Integer, documentation: { x: nil }
      end

      expect(subject.validate_attributes_reader).to eq(
        [
          [:vault], { type: Integer, documentation: { x: nil } }
        ]
      )
    end

    it 'does not nest primitives inside existing complex types erroneously' do
      subject.with(type: Hash, documentation: { default: { vault: '33' } }) do
        subject.optional :info
        subject.optional :role, type: String, documentation: { default: 'resident' }
      end

      expect(subject.validate_attributes_reader).to eq(
        [
          [:info], { type: Hash, documentation: { default: { vault: '33' } } },
          [:role], { type: String, documentation: { default: 'resident' } }
        ]
      )
    end

    it 'merges deeply nested attributes' do
      subject.with(documentation: { details: { in: 'body', hidden: false } }) do
        subject.optional :vault, documentation: { details: { desc: 'The vault number' } }
      end

      expect(subject.validate_attributes_reader).to eq(
        [
          [:vault], { documentation: { details: { in: 'body', hidden: false, desc: 'The vault number' } } }
        ]
      )
    end

    it "supports nested 'with' calls" do
      subject.with(type: Integer, documentation: { in: 'body' }) do
        subject.optional :pipboy_id
        subject.with(documentation: { default: 33 }) do
          subject.optional :vault
          subject.with(type: String) do
            subject.with(documentation: { default: 'resident' }) do
              subject.optional :role
            end
          end
          subject.optional :age, documentation: { default: 42 }
        end
      end

      expect(subject.validate_attributes_reader).to eq(
        [
          [:pipboy_id], { type: Integer, documentation: { in: 'body' } },
          [:vault], { type: Integer, documentation: { in: 'body', default: 33 } },
          [:role], { type: String, documentation: { in: 'body', default: 'resident' } },
          [:age], { type: Integer, documentation: { in: 'body', default: 42 } }
        ]
      )
    end

    it "supports Hash parameter inside the 'with' calls" do
      subject.with(documentation: { in: 'body' }) do
        subject.optional :info, type: Hash, documentation: { x: { nullable: true }, desc: 'The info' } do
          subject.optional :vault, type: Integer, documentation: { default: 33, desc: 'The vault number' }
        end
      end

      expect(subject.validate_attributes_reader).to eq(
        [
          [:info], { type: Hash, documentation: { in: 'body', desc: 'The info', x: { nullable: true } } },
          [:vault], { type: Integer, documentation: { in: 'body', default: 33, desc: 'The vault number' } }
        ]
      )
    end
  end

  describe '#mutually_exclusive' do
    it 'adds an mutally exclusive parameter validation' do
      subject.mutually_exclusive :media, :audio

      expect(subject.validates_reader).to eq([%i[media audio], { mutual_exclusion: { value: true, message: nil } }])
    end
  end

  describe '#exactly_one_of' do
    it 'adds an exactly of one parameter validation' do
      subject.exactly_one_of :media, :audio

      expect(subject.validates_reader).to eq([%i[media audio], { exactly_one_of: { value: true, message: nil } }])
    end
  end

  describe '#at_least_one_of' do
    it 'adds an at least one of parameter validation' do
      subject.at_least_one_of :media, :audio

      expect(subject.validates_reader).to eq([%i[media audio], { at_least_one_of: { value: true, message: nil } }])
    end
  end

  describe '#all_or_none_of' do
    it 'adds an all or none of parameter validation' do
      subject.all_or_none_of :media, :audio

      expect(subject.validates_reader).to eq([%i[media audio], { all_or_none_of: { value: true, message: nil } }])
    end
  end

  describe '#group' do
    it 'is alias to #requires' do
      expect(subject.method(:group)).to eq subject.method(:requires)
    end
  end

  describe '#params' do
    it 'inherits params from parent' do
      parent_params = { foo: 'bar' }
      subject.parent = Object.new
      allow(subject.parent).to receive(:params).and_return(parent_params)
      expect(subject.params({})).to eq parent_params
    end

    describe 'when params argument is an array of hashes' do
      it 'returns values of each hash for @element key' do
        subject.element = :foo
        expect(subject.params([{ foo: 'bar' }, { foo: 'baz' }])).to eq(%w[bar baz])
      end
    end

    describe 'when params argument is a hash' do
      it 'returns value for @element key' do
        subject.element = :foo
        expect(subject.params(foo: 'bar')).to eq('bar')
      end
    end

    describe 'when params argument is not a array or a hash' do
      it 'returns empty hash' do
        subject.element = Object.new
        expect(subject.params(Object.new)).to eq({})
      end
    end
  end
end
