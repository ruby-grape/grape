# frozen_string_literal: true

describe Grape::DSL::Versioning do
  subject { dummy_class }

  let(:dummy_class) do
    Class.new do
      extend Grape::DSL::Versioning
      extend Grape::DSL::Settings
    end
  end

  describe '.version' do
    it 'sets a version for route' do
      version = 'v1'
      expect(subject.version(version)).to eq(version)
      expect(subject.inheritable_setting.version).to eq([version])
      expect(subject.inheritable_setting.version_options).to eq(Grape::DSL::VersionOptions.new)
    end
  end

  describe '.versions' do
    it 'returns last defined version' do
      subject.version 'v1'
      subject.version 'v2'
      expect(subject.version).to eq('v2')
    end
  end
end
