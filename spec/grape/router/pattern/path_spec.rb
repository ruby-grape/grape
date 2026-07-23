# frozen_string_literal: true

RSpec.describe Grape::Router::Pattern::Path do
  def path_settings(**attrs)
    Grape::Util::InheritableSetting::PathSettings.new(
      mount_path: nil, root_prefix: nil, format: nil, content_types: nil, version: nil, version_options: nil, **attrs
    )
  end

  describe '#origin' do
    context 'mount_path' do
      it 'is not included when it is nil' do
        path = described_class.new(nil, nil, path_settings(mount_path: '/foo/bar'))
        expect(path.origin).to eql '/foo/bar'
      end

      it 'is included when it is not nil' do
        path = described_class.new(nil, nil, path_settings)
        expect(path.origin).to eql('/')
      end
    end

    context 'root_prefix' do
      it 'is not included when it is nil' do
        path = described_class.new(nil, nil, path_settings)
        expect(path.origin).to eql('/')
      end

      it 'is included after the mount path' do
        path = described_class.new(
          nil,
          nil,
          path_settings(mount_path: '/foo', root_prefix: '/hello')
        )

        expect(path.origin).to eql('/foo/hello')
      end
    end

    it 'uses the namespace after the mount path and root prefix' do
      path = described_class.new(
        nil,
        'namespace',
        path_settings(mount_path: '/foo', root_prefix: '/hello')
      )

      expect(path.origin).to eql('/foo/hello/namespace')
    end

    it 'uses the raw path after the namespace' do
      path = described_class.new(
        'raw_path',
        'namespace',
        path_settings(mount_path: '/foo', root_prefix: '/hello')
      )

      expect(path.origin).to eql('/foo/hello/namespace/raw_path')
    end
  end

  describe '#suffix' do
    context 'when using a specific format' do
      it 'accepts specified format' do
        path = described_class.new(nil, nil, path_settings(format: 'json', content_types: 'application/json'))
        expect(path.suffix).to eql('(.json)')
      end
    end

    context 'when path versioning is used' do
      it "includes a '/'" do
        path = described_class.new(nil, nil, path_settings(version: :v1, version_options: Grape::DSL::VersionOptions.new))
        expect(path.suffix).to eql('(/.:format)')
      end
    end

    context 'when path versioning is not used' do
      it "does not include a '/' when the path has a namespace" do
        path = described_class.new(nil, 'namespace', path_settings)
        expect(path.suffix).to eql('(.:format)')
      end

      it "does not include a '/' when the path has a path" do
        path = described_class.new('/path', nil, path_settings(version: :v1, version_options: Grape::DSL::VersionOptions.new))
        expect(path.suffix).to eql('(.:format)')
      end

      it "includes a '/' otherwise" do
        path = described_class.new(nil, nil, path_settings(version: :v1, version_options: Grape::DSL::VersionOptions.new))
        expect(path.suffix).to eql('(/.:format)')
      end
    end
  end
end
