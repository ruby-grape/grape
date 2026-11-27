# frozen_string_literal: true

describe Grape::API do
  context 'when mounting a subclass of an API' do
    let(:trail) do
      Class.new(Grape::Middleware::Base) do
        def before = (env['spec.trail'] ||= []) << 'middleware'
      end
    end

    let(:base_api) do
      trail = self.trail
      Class.new(described_class) do
        prefix 'v2'
        format :json
        use trail
        helpers do
          def current_user = 'alice'
        end
        before do
          error!('Unauthorized', 401) unless headers['X-Token'] == 'secret'
          env['spec.trail'] << 'base'
        end

        rescue_from(ArgumentError) { error!('rescued by the superclass', 418) }
      end
    end

    let(:sub_api) do
      Class.new(base_api) do
        get(:user) { { user: current_user } }
        get(:trail) { env['spec.trail'] }
        get(:raise) { raise ArgumentError }
      end
    end

    def app
      api = sub_api
      Class.new(described_class) { mount api }
    end

    it 'keeps the helpers its superclass declares' do
      get '/v2/user', {}, 'HTTP_X_TOKEN' => 'secret'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq({ user: 'alice' }.to_json)
    end

    it 'runs the before filters its superclass declares' do
      get '/v2/user'
      expect(last_response.status).to eq(401)
    end

    it 'goes through the middleware its superclass declares' do
      get '/v2/trail', {}, 'HTTP_X_TOKEN' => 'secret'
      expect(last_response.body).to eq(%w[middleware base].to_json)
    end

    it 'rescues with the handlers its superclass declares' do
      get '/v2/raise', {}, 'HTTP_X_TOKEN' => 'secret'
      expect(last_response.status).to eq(418)
      expect(last_response.body).to eq({ error: 'rescued by the superclass' }.to_json)
    end

    it 'takes the prefix its superclass declares, as it would its own' do
      own_prefix = Class.new(described_class) do
        prefix 'v2'
        get(:own) { 'own' }
      end
      api = sub_api
      mounting = Class.new(described_class) do
        mount api => '/x'
        mount own_prefix => '/x'
      end

      expect(mounting.routes.map(&:path)).to include('/x/v2/user(.json)', '/x/v2/own(.:format)')
    end

    it 'keeps what each of its superclasses declares' do
      middle = Class.new(base_api) do
        helpers do
          def role = 'admin'
        end
      end
      leaf = Class.new(middle) do
        get(:whoami) { { user: current_user, role: } }
      end
      mounting = Class.new(described_class) { mount leaf }

      response = Rack::MockRequest.new(mounting).get('/v2/whoami', 'HTTP_X_TOKEN' => 'secret')
      expect(response.body).to eq({ user: 'alice', role: 'admin' }.to_json)
    end

    context 'when the API mounting it inherits from the same superclass' do
      def app
        api = sub_api
        Class.new(base_api) do
          before { env['spec.trail'] << 'root' }

          mount api
        end
      end

      it 'applies what the superclass declares once' do
        get '/v2/trail', {}, 'HTTP_X_TOKEN' => 'secret'
        expect(last_response.body).to eq(%w[middleware base root].to_json)
      end
    end

    context 'when it inherits from a subclass of the superclass the mounting API inherits from' do
      def app
        authed = Class.new(base_api) { before { env['spec.trail'] << 'authed' } }
        api = Class.new(authed) { get(:trail) { env['spec.trail'] } }
        Class.new(base_api) { mount api }
      end

      it 'applies what the superclass declares once and what the subclass declares too' do
        get '/v2/trail', {}, 'HTTP_X_TOKEN' => 'secret'
        expect(last_response.body).to eq(%w[middleware base authed].to_json)
      end
    end

    context 'when the API in between does not inherit from the superclass, but the one mounting it does' do
      def app
        api = sub_api
        between = Class.new(described_class) { mount api }
        Class.new(base_api) { mount between }
      end

      it 'applies what the superclass declares once' do
        get '/v2/trail', {}, 'HTTP_X_TOKEN' => 'secret'
        expect(last_response.body).to eq(%w[middleware base].to_json)
      end
    end
  end
end
