# frozen_string_literal: true

if defined?(Rails)
  # Named by string: the constant would autoload lib/grape/railtie.rb itself and
  # hide whether requiring grape after rails loaded it.
  describe 'Grape::Railtie' do
    describe '.railtie' do
      subject { test_app.deprecators[:grape] }

      let(:test_app) do
        # https://github.com/rails/rails/issues/51784
        # same error as described if not redefining the following
        ActiveSupport::Dependencies.autoload_paths = []
        ActiveSupport::Dependencies.autoload_once_paths = []

        Class.new(Rails::Application) do
          config.eager_load = false
          config.load_defaults "#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}"
        end
      end

      before { test_app.initialize! }

      it { is_expected.to be(Grape.deprecator) }
    end

    describe 'compiling the APIs mounted in the routes' do
      let(:api) { Class.new(Grape::API) { get('/ping') { 'pong' } } }
      let(:mounted) { api }
      let(:eager_load) { true }

      let(:test_app) do
        require 'action_controller/railtie'
        # Every application shares config.action_view, and load_defaults below
        # writes settings back into it that ActionView::Base has no setter for.
        # Loading ActionView::Base first runs the :action_view hooks an earlier
        # example's application left pending, before they can read them;
        # eager loading would otherwise load it in the middle of the boot.
        require 'action_view/base'

        # https://github.com/rails/rails/issues/51784
        # same error as described if not redefining the following
        ActiveSupport::Dependencies.autoload_paths = []
        ActiveSupport::Dependencies.autoload_once_paths = []

        eager = eager_load
        app = mounted
        Class.new(Rails::Application) do
          config.eager_load = eager
          config.load_defaults "#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}"
          routes.append { mount app => '/' }
        end
      end

      # Eager loading calls I18n.eager_load!, after which the backend reloads its
      # translations at once on every I18n.reload!, under whatever
      # available_locales a later example has set, instead of on the next lookup.
      around do |example|
        backend = I18n.backend
        I18n.backend = I18n::Backend::Simple.new
        example.run
      ensure
        I18n.backend = backend
      end

      before do
        stub_const('GrapeApi', api)
        # Rails 8 hands after_routes_loaded Rails.application, which is memoized
        # to the first application this process initialized.
        allow(Rails).to receive(:application).and_return(test_app.instance)
      end

      context 'when Rails eager loads' do
        it 'compiles them at boot' do
          expect(api).to receive(:compile!).and_call_original
          test_app.initialize!
        end
      end

      context 'when Rails does not eager load' do
        let(:eager_load) { false }

        it 'leaves them to the first request' do
          expect(api).not_to receive(:compile!)
          test_app.initialize!
        end
      end

      context 'when an engine mounts the API' do
        let(:engine) { Class.new(Rails::Engine) }
        let(:mounted) { engine }

        before do
          stub_const('GrapeEngine', engine)
          mounted_api = api
          engine.routes.append { mount mounted_api => '/' }
        end

        it 'compiles it at boot' do
          expect(api).to receive(:compile!).and_call_original
          test_app.initialize!
        end
      end
    end
  end
end
