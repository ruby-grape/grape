# frozen_string_literal: true

describe Grape::DSL::Settings do
  subject { dummy_class.new }

  let(:dummy_class) do
    Class.new do
      include Grape::DSL::Settings

      def with_namespace(&block)
        within_namespace(&block)
      end

      def reset_validations!; end
    end
  end

  describe '#global_setting' do
    it 'sets a value globally' do
      subject.global_setting :some_thing, :foo_bar
      expect(subject.global_setting(:some_thing)).to eq :foo_bar
      subject.with_namespace do
        subject.global_setting :some_thing, :foo_bar_baz
        expect(subject.global_setting(:some_thing)).to eq :foo_bar_baz
      end
      expect(subject.global_setting(:some_thing)).to eq(:foo_bar_baz)
    end
  end

  describe '#route_setting' do
    it 'sets a value until the end of a namespace' do
      subject.with_namespace do
        subject.route_setting :some_thing, :foo_bar
        expect(subject.route_setting(:some_thing)).to eq :foo_bar
      end
      expect(subject.route_setting(:some_thing)).to be_nil
    end
  end

  describe '#namespace_setting' do
    it 'sets a value until the end of a namespace' do
      subject.with_namespace do
        subject.namespace_setting :some_thing, :foo_bar
        expect(subject.namespace_setting(:some_thing)).to eq :foo_bar
      end
      expect(subject.namespace_setting(:some_thing)).to be_nil
    end

    it 'resets values after leaving nested namespaces' do
      subject.with_namespace do
        subject.namespace_setting :some_thing, :foo_bar
        expect(subject.namespace_setting(:some_thing)).to eq :foo_bar
        subject.with_namespace do
          expect(subject.namespace_setting(:some_thing)).to be_nil
        end
        expect(subject.namespace_setting(:some_thing)).to eq :foo_bar
      end
      expect(subject.namespace_setting(:some_thing)).to be_nil
    end
  end

  describe '#namespace_inheritable' do
    it 'inherits values from surrounding namespace' do
      subject.with_namespace do
        subject.inheritable_setting.namespace_inheritable[:some_thing] = :foo_bar
        expect(subject.inheritable_setting.namespace_inheritable[:some_thing]).to eq :foo_bar
        subject.with_namespace do
          expect(subject.inheritable_setting.namespace_inheritable[:some_thing]).to eq :foo_bar
          subject.inheritable_setting.namespace_inheritable[:some_thing] = :foo_bar_2
          expect(subject.inheritable_setting.namespace_inheritable[:some_thing]).to eq :foo_bar_2
        end
        expect(subject.inheritable_setting.namespace_inheritable[:some_thing]).to eq :foo_bar
      end
    end
  end

  describe '#namespace_stackable' do
    it 'stacks values from surrounding namespace' do
      subject.with_namespace do
        subject.inheritable_setting.namespace_stackable[:some_thing] = :foo_bar
        expect(subject.inheritable_setting.namespace_stackable[:some_thing]).to eq [:foo_bar]
        subject.with_namespace do
          subject.inheritable_setting.namespace_stackable[:some_thing] = :foo_bar_2
          expect(subject.inheritable_setting.namespace_stackable[:some_thing]).to eq %i[foo_bar foo_bar_2]
        end
        expect(subject.inheritable_setting.namespace_stackable[:some_thing]).to eq [:foo_bar]
      end
    end
  end

  describe 'complex scenario' do
    it 'plays well' do
      obj1 = dummy_class.new
      obj2 = dummy_class.new
      obj3 = dummy_class.new

      obj1_copy = nil
      obj2_copy = nil
      obj3_copy = nil

      obj1.with_namespace do
        obj1.inheritable_setting.namespace_stackable[:some_thing] = :obj1
        expect(obj1.inheritable_setting.namespace_stackable[:some_thing]).to eq [:obj1]
        obj1_copy = obj1.inheritable_setting.point_in_time_copy
      end

      expect(obj1.inheritable_setting.namespace_stackable[:some_thing]).to eq []
      expect(obj1_copy.namespace_stackable[:some_thing]).to eq [:obj1]

      obj2.with_namespace do
        obj2.inheritable_setting.namespace_stackable[:some_thing] = :obj2
        expect(obj2.inheritable_setting.namespace_stackable[:some_thing]).to eq [:obj2]
        obj2_copy = obj2.inheritable_setting.point_in_time_copy
      end

      expect(obj2.inheritable_setting.namespace_stackable[:some_thing]).to eq []
      expect(obj2_copy.namespace_stackable[:some_thing]).to eq [:obj2]

      obj3.with_namespace do
        obj3.inheritable_setting.namespace_stackable[:some_thing] = :obj3
        expect(obj3.inheritable_setting.namespace_stackable[:some_thing]).to eq [:obj3]
        obj3_copy = obj3.inheritable_setting.point_in_time_copy
      end

      expect(obj3.inheritable_setting.namespace_stackable[:some_thing]).to eq []
      expect(obj3_copy.namespace_stackable[:some_thing]).to eq [:obj3]

      # obj1.top_level_setting.inherit_from obj2_copy.point_in_time_copy
      # obj2.top_level_setting.inherit_from obj3_copy.point_in_time_copy

      # expect(obj1_copy.namespace_stackable[:some_thing]).to eq %i[obj3 obj2 obj1]
    end
  end
end
