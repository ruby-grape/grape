# frozen_string_literal: true

if defined?(Rails) && ActiveSupport.gem_version >= Gem::Version.new('7.1')
  describe Grape::Railtie do
    describe '.railtie' do
      subject { test_app.deprecators[:grape] }

      let(:test_app) do
        Class.new(Rails::Application) do
          config.eager_load = false
          config.load_defaults "#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}"
        end
      end

      before { test_app.initialize! }

      it { is_expected.to be(Grape.deprecator) }
    end
  end
end
