# frozen_string_literal: true

describe Grape::Util::Registry do
  # Create a test class that includes the Registry module
  subject { test_registry_class.new }

  let(:test_registry_class) do
    Class.new do
      include Grape::Util::Registry

      # Public methods to expose private functionality for testing
      def registry_empty?
        registry.empty?
      end

      def registry_get(key)
        registry[key]
      end
    end
  end

  describe '#register' do
    let(:test_class) do
      Class.new do
        def self.name
          'TestModule::TestClass'
        end
      end
    end

    let(:simple_class) do
      Class.new do
        def self.name
          'SimpleClass'
        end
      end
    end

    let(:camel_case_class) do
      Class.new do
        def self.name
          'CamelCaseClass'
        end
      end
    end

    let(:anonymous_class) { Class.new }

    let(:nil_name_class) do
      Class.new do
        def self.name
          nil
        end
      end
    end

    let(:empty_name_class) do
      Class.new do
        def self.name
          ''
        end
      end
    end

    context 'with valid class names' do
      it 'registers a class with demodulized and underscored name' do
        subject.register(test_class)
        expect(subject.registry_get('test_class')).to eq(test_class)
      end

      it 'registers a simple class name correctly' do
        subject.register(simple_class)
        expect(subject.registry_get('simple_class')).to eq(simple_class)
      end

      it 'handles camel case class names' do
        subject.register(camel_case_class)
        expect(subject.registry_get('camel_case_class')).to eq(camel_case_class)
      end

      it 'uses indifferent access for registry keys' do
        subject.register(test_class)
        expect(subject.registry_get(:test_class)).to eq(test_class)
        expect(subject.registry_get('test_class')).to eq(test_class)
      end
    end

    context 'with invalid class names' do
      it 'does not register anonymous classes' do
        subject.register(anonymous_class)
        expect(subject.registry_empty?).to be true
      end

      it 'does not register classes with nil names' do
        subject.register(nil_name_class)
        expect(subject.registry_empty?).to be true
      end

      it 'does not register classes with empty names' do
        subject.register(empty_name_class)
        expect(subject.registry_empty?).to be true
      end
    end

    context 'with duplicate registrations' do
      it 'warns when registering a duplicate short name' do
        expect do
          subject.register(test_class)
          subject.register(test_class)
        end.to output(/test_class is already registered with class.*It will be overridden/).to_stderr
      end

      it 'warns with correct short name for different class types' do
        expect do
          subject.register(simple_class)
          subject.register(simple_class)
        end.to output(/simple_class is already registered with class.*It will be overridden/).to_stderr
      end

      it 'warns with correct short name for camel case classes' do
        expect do
          subject.register(camel_case_class)
          subject.register(camel_case_class)
        end.to output(/camel_case_class is already registered with class.*It will be overridden/).to_stderr
      end

      it 'warns for each duplicate registration' do
        expect do
          subject.register(test_class)
          subject.register(test_class)
          subject.register(test_class) # Third registration should warn again
        end.to output(/test_class is already registered with class.*It will be overridden/).to_stderr
      end

      it 'warns with exact message format' do
        expected_message = "test_class is already registered with class #{test_class}. It will be overridden globally with the following: #{test_class.name}"
        expect do
          subject.register(test_class)
          subject.register(test_class)
        end.to output(/#{Regexp.escape(expected_message)}/).to_stderr
      end

      it 'overwrites existing registration when duplicate short name is registered' do
        subject.register(test_class)
        subject.register(test_class)

        expect(subject.registry_get('test_class')).to eq(test_class)
      end
    end
  end

  describe 'edge cases' do
    it 'handles classes with special characters in names' do
      special_class = Class.new do
        def self.name
          'Special::Class::With::Many::Modules'
        end
      end

      subject.register(special_class)
      expect(subject.registry_get('modules')).to eq(special_class)
    end

    it 'handles classes with numbers in names' do
      numbered_class = Class.new do
        def self.name
          'Class123WithNumbers'
        end
      end

      subject.register(numbered_class)
      expect(subject.registry_get('class123_with_numbers')).to eq(numbered_class)
    end

    it 'handles classes with acronyms' do
      acronym_class = Class.new do
        def self.name
          'API::HTTPClient'
        end
      end

      subject.register(acronym_class)
      expect(subject.registry_get('http_client')).to eq(acronym_class)
    end
  end
end
