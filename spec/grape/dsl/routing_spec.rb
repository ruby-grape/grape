require 'spec_helper'

module Grape
  module DSL
    module RoutingSpec
      class Dummy
        include Grape::DSL::Routing
      end
    end

    describe Routing do
      subject { Class.new(RoutingSpec::Dummy) }
      let(:proc) { ->() {} }
      let(:options) { { a: :b } }
      let(:path) { '/dummy' }

      describe '.version' do
        it 'sets a version for route' do
          version = 'v1'
          expect(subject).to receive(:namespace_inheritable).with(:version, [version])
          expect(subject).to receive(:namespace_inheritable).with(:version_options, using: :path)
          expect(subject.version(version)).to eq(version)
        end
      end

      describe '.prefix' do
        it 'sets a prefix for route' do
          prefix = '/api'
          expect(subject).to receive(:namespace_inheritable).with(:root_prefix, prefix)
          subject.prefix prefix
        end
      end

      describe '.do_not_route_head!' do
        it 'sets do not route head option' do
          expect(subject).to receive(:namespace_inheritable).with(:do_not_route_head, true)
          subject.do_not_route_head!
        end
      end

      describe '.do_not_route_options!' do
        it 'sets do not route options option' do
          expect(subject).to receive(:namespace_inheritable).with(:do_not_route_options, true)
          subject.do_not_route_options!
        end
      end

      describe '.mount' do
        it 'mounts on a nested path' do
          subject = Class.new(Grape::API)
          app1 = Class.new(Grape::API)
          app2 = Class.new(Grape::API)
          app2.get '/nice' do
            'play'
          end

          subject.mount app1 => '/app1'
          app1.mount app2 => '/app2'

          expect(subject.inheritable_setting.to_hash[:namespace]).to eq({})
          expect(subject.inheritable_setting.to_hash[:namespace_inheritable]).to eq({})
          expect(app1.inheritable_setting.to_hash[:namespace_stackable]).to eq(:mount_path => ['/app1'])

          expect(app2.inheritable_setting.to_hash[:namespace_stackable]).to eq(:mount_path => ['/app1', '/app2'])
        end
      end
      xdescribe '.route' do
        it 'does some thing'
      end

      describe '.get' do
        it 'delegates to .route' do
          expect(subject).to receive(:route).with('GET', path, options)
          subject.get path, options, &proc
        end
      end

      describe '.post' do
        it 'delegates to .route' do
          expect(subject).to receive(:route).with('POST', path, options)
          subject.post path, options, &proc
        end
      end

      describe '.put' do
        it 'delegates to .route' do
          expect(subject).to receive(:route).with('PUT', path, options)
          subject.put path, options, &proc
        end
      end

      describe '.head' do
        it 'delegates to .route' do
          expect(subject).to receive(:route).with('HEAD', path, options)
          subject.head path, options, &proc
        end
      end

      describe '.delete' do
        it 'delegates to .route' do
          expect(subject).to receive(:route).with('DELETE', path, options)
          subject.delete path, options, &proc
        end
      end

      describe '.options' do
        it 'delegates to .route' do
          expect(subject).to receive(:route).with('OPTIONS', path, options)
          subject.options path, options, &proc
        end
      end

      describe '.patch' do
        it 'delegates to .route' do
          expect(subject).to receive(:route).with('PATCH', path, options)
          subject.patch path, options, &proc
        end
      end

      xdescribe '.namespace' do
        it 'does some thing'
      end

      xdescribe '.group' do
        it 'does some thing'
      end

      xdescribe '.resource' do
        it 'does some thing'
      end

      xdescribe '.resources' do
        it 'does some thing'
      end

      xdescribe '.segment' do
        it 'does some thing'
      end

      xdescribe '.routes' do
        it 'does some thing'
      end

      xdescribe '.route_param' do
        it 'does some thing'
      end

      describe '.versions' do
        it 'returns last defined version' do
          subject.version 'v1'
          subject.version 'v2'
          expect(subject.version).to eq('v2')
        end
      end
    end
  end
end
