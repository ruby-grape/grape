# frozen_string_literal: true

module Grape
  describe Path do
    describe '#initialize' do
      it 'remembers the path' do
        path = described_class.new('/:id', anything, anything)
        expect(path.raw_path).to eql('/:id')
      end

      it 'remembers the namespace' do
        path = described_class.new(anything, '/users', anything)
        expect(path.namespace).to eql('/users')
      end

      it 'remebers the settings' do
        path = described_class.new(anything, anything, foo: 'bar')
        expect(path.settings).to eql(foo: 'bar')
      end
    end

    describe '#mount_path' do
      it 'is nil when no mount path setting exists' do
        path = described_class.new(anything, anything, {})
        expect(path.mount_path).to be_nil
      end

      it 'is nil when the mount path is nil' do
        path = described_class.new(anything, anything, mount_path: nil)
        expect(path.mount_path).to be_nil
      end

      it 'splits the mount path' do
        path = described_class.new(anything, anything, mount_path: %w[foo bar])
        expect(path.mount_path).to eql(%w[foo bar])
      end
    end

    describe '#root_prefix' do
      it 'is nil when no root prefix setting exists' do
        path = described_class.new(anything, anything, {})
        expect(path.root_prefix).to be_nil
      end

      it 'is nil when the mount path is nil' do
        path = described_class.new(anything, anything, root_prefix: nil)
        expect(path.root_prefix).to be_nil
      end

      it 'splits the mount path' do
        path = described_class.new(anything, anything, root_prefix: 'hello/world')
        expect(path.root_prefix).to eql(%w[hello world])
      end
    end

    describe '#uses_path_versioning?' do
      it 'is false when the version setting is nil' do
        path = described_class.new(anything, anything, version: nil)
        expect(path.uses_path_versioning?).to be false
      end

      it 'is false when the version option is header' do
        path = described_class.new(
          anything,
          anything,
          version: 'v1',
          version_options: { using: :header }
        )

        expect(path.uses_path_versioning?).to be false
      end

      it 'is true when the version option is path' do
        path = described_class.new(
          anything,
          anything,
          version: 'v1',
          version_options: { using: :path }
        )

        expect(path.uses_path_versioning?).to be true
      end
    end

    describe '#namespace?' do
      it 'is false when the namespace is nil' do
        path = described_class.new(anything, nil, anything)
        expect(path).not_to be_namespace
      end

      it 'is false when the namespace starts with whitespace' do
        path = described_class.new(anything, ' /foo', anything)
        expect(path).not_to be_namespace
      end

      it 'is false when the namespace is the root path' do
        path = described_class.new(anything, '/', anything)
        expect(path.namespace?).to be false
      end

      it 'is true otherwise' do
        path = described_class.new(anything, '/world', anything)
        expect(path.namespace?).to be true
      end
    end

    describe '#path?' do
      it 'is false when the path is nil' do
        path = described_class.new(nil, anything, anything)
        expect(path).not_to be_path
      end

      it 'is false when the path starts with whitespace' do
        path = described_class.new(' /foo', anything, anything)
        expect(path).not_to be_path
      end

      it 'is false when the path is the root path' do
        path = described_class.new('/', anything, anything)
        expect(path.path?).to be false
      end

      it 'is true otherwise' do
        path = described_class.new('/hello', anything, anything)
        expect(path.path?).to be true
      end
    end

    describe '#path' do
      context 'mount_path' do
        it 'is not included when it is nil' do
          path = described_class.new(nil, nil, mount_path: '/foo/bar')
          expect(path.path).to eql '/foo/bar'
        end

        it 'is included when it is not nil' do
          path = described_class.new(nil, nil, {})
          expect(path.path).to eql('/')
        end
      end

      context 'root_prefix' do
        it 'is not included when it is nil' do
          path = described_class.new(nil, nil, {})
          expect(path.path).to eql('/')
        end

        it 'is included after the mount path' do
          path = described_class.new(
            nil,
            nil,
            mount_path: '/foo',
            root_prefix: '/hello'
          )

          expect(path.path).to eql('/foo/hello')
        end
      end

      it 'uses the namespace after the mount path and root prefix' do
        path = described_class.new(
          nil,
          'namespace',
          mount_path: '/foo',
          root_prefix: '/hello'
        )

        expect(path.path).to eql('/foo/hello/namespace')
      end

      it 'uses the raw path after the namespace' do
        path = described_class.new(
          'raw_path',
          'namespace',
          mount_path: '/foo',
          root_prefix: '/hello'
        )

        expect(path.path).to eql('/foo/hello/namespace/raw_path')
      end
    end

    describe '#suffix' do
      context 'when using a specific format' do
        it 'accepts specified format' do
          path = described_class.new(nil, nil, {})
          allow(path).to receive(:uses_specific_format?).and_return(true)
          allow(path).to receive(:settings).and_return({ format: :json })

          expect(path.suffix).to eql('(.json)')
        end
      end

      context 'when path versioning is used' do
        it "includes a '/'" do
          path = described_class.new(nil, nil, {})
          allow(path).to receive(:uses_specific_format?).and_return(false)
          allow(path).to receive(:uses_path_versioning?).and_return(true)

          expect(path.suffix).to eql('(/.:format)')
        end
      end

      context 'when path versioning is not used' do
        it "does not include a '/' when the path has a namespace" do
          path = described_class.new(nil, 'namespace', {})
          allow(path).to receive(:uses_specific_format?).and_return(false)
          allow(path).to receive(:uses_path_versioning?).and_return(true)

          expect(path.suffix).to eql('(.:format)')
        end

        it "does not include a '/' when the path has a path" do
          path = described_class.new('/path', nil, {})
          allow(path).to receive(:uses_specific_format?).and_return(false)
          allow(path).to receive(:uses_path_versioning?).and_return(true)

          expect(path.suffix).to eql('(.:format)')
        end

        it "includes a '/' otherwise" do
          path = described_class.new(nil, nil, {})
          allow(path).to receive(:uses_specific_format?).and_return(false)
          allow(path).to receive(:uses_path_versioning?).and_return(true)

          expect(path.suffix).to eql('(/.:format)')
        end
      end
    end

    describe '#path_with_suffix' do
      it 'combines the path and suffix' do
        path = described_class.new(nil, nil, {})
        allow(path).to receive(:path).and_return('/the/path')
        allow(path).to receive(:suffix).and_return('suffix')

        expect(path.path_with_suffix).to eql('/the/pathsuffix')
      end

      context 'when using a specific format' do
        it 'might have a suffix with specified format' do
          path = described_class.new(nil, nil, {})
          allow(path).to receive(:path).and_return('/the/path')
          allow(path).to receive(:uses_specific_format?).and_return(true)
          allow(path).to receive(:settings).and_return({ format: :json })

          expect(path.path_with_suffix).to eql('/the/path(.json)')
        end
      end
    end
  end
end
