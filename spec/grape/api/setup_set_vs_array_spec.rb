# frozen_string_literal: true

require 'spec_helper'

module SetupSetVsArraySpec
  class SetupSetAPI < Grape::API
    class << self
      def initial_setup(*)
        super
        # @setup should be an empty at this point, but just in case it isn't, use to_set
        @setup = @setup.to_set
      end
    end
  end

  class SetupArrayAPI < Grape::API
    class << self
      def initial_setup(*)
        super
        # @setup should be an empty at this point, but just in case it isn't, use to_a
        @setup = @setup.to_a
      end
    end
  end

  class SetExample < SetupSetAPI
    desc 'Identical description'
    route_setting :custom, key: 'value'
    route_setting :custom_diff, key: 'foo'
    get '/api1' do
      status 200
    end

    desc 'Identical description'
    route_setting :custom, key: 'value'
    route_setting :custom_diff, key: 'bar'
    get '/api2' do
      status 200
    end
  end

  class ArrayExample < SetupArrayAPI
    desc 'Identical description'
    route_setting :custom, key: 'value'
    route_setting :custom_diff, key: 'foo'
    get '/api1' do
      status 200
    end

    desc 'Identical description'
    route_setting :custom, key: 'value'
    route_setting :custom_diff, key: 'bar'
    get '/api2' do
      status 200
    end
  end

  class MountedSetExample < Grape::API
    mount SetExample
  end

  class MountedArrayExample < Grape::API
    mount ArrayExample
  end
end

# @see https://github.com/ruby-grape/grape/issues/2173
# These specs are here to show that Grape::API's `@setup` variable should NOT be a Set,
# because when it is, identical DSL calls are ignored when the API is mounted, leading to missing settings.
describe Grape::API do
  describe SetupSetVsArraySpec::MountedSetExample do
    subject { described_class }

    it 'has two routes' do
      expect(subject.routes.count).to be(2)
    end

    it 'has a first route with all the settings' do
      expect(subject.routes[0].settings).to include(
        {
          description: { description: 'Identical description' },
          custom: { key: 'value' },
          custom_diff: { key: 'foo' }
        }
      )
    end

    it 'has a second route with only custom_diff setting (no description or custom)' do
      expect(subject.routes[1].settings).to include({ custom_diff: { key: 'bar' } })
      expect(subject.routes[1].settings).not_to include(:description, :custom)
    end
  end

  describe SetupSetVsArraySpec::MountedArrayExample do
    subject { described_class }

    it 'has two routes' do
      expect(subject.routes.count).to be(2)
    end

    it 'has a first route with all the settings' do
      expect(subject.routes[0].settings).to include(
        {
          description: { description: 'Identical description' },
          custom: { key: 'value' },
          custom_diff: { key: 'foo' }
        }
      )
    end

    it 'has a second route with all the settings' do
      expect(subject.routes[1].settings).to include(
        {
          description: { description: 'Identical description' },
          custom: { key: 'value' },
          custom_diff: { key: 'bar' }
        }
      )
    end
  end
end
