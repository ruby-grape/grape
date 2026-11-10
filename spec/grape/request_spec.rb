# frozen_string_literal: true

describe Grape::Request do
  let(:default_method) { Rack::GET }
  let(:default_params) { {} }
  let(:default_options) do
    {
      method:,
      params:
    }
  end
  let(:default_env) do
    Rack::MockRequest.env_for('/', options)
  end
  let(:method) { default_method }
  let(:params) { default_params }
  let(:options) { default_options }
  let(:env) { default_env }

  let(:request) do
    described_class.new(env)
  end

  describe '#params' do
    let(:params) do
      {
        a: '123',
        b: 'xyz'
      }
    end

    it 'by default returns stringified parameter keys' do
      expect(request.params).to eq(ActiveSupport::HashWithIndifferentAccess.new('a' => '123', 'b' => 'xyz'))
    end

    context 'when build_params_with: Grape::Extensions::Hash::ParamBuilder is specified' do
      let(:request) do
        described_class.new(env, build_params_with: :hash)
      end

      it 'returns symbolized params' do
        expect(request.params).to eq(a: '123', b: 'xyz')
      end
    end

    describe 'with grape.routing_args' do
      let(:options) do
        default_options.merge('grape.routing_args' => routing_args)
      end
      let(:routing_args) do
        {
          version: '123',
          route_info: instance_double(Grape::Router::Route, version: route_version),
          c: 'ccc'
        }
      end

      context 'when the route carries a version of its own' do
        let(:route_version) { 'v1' }

        it 'cuts version and route_info' do
          expect(request.params).to eq(ActiveSupport::HashWithIndifferentAccess.new(a: '123', b: 'xyz', c: 'ccc'))
        end
      end

      # Without a declared version the captured segment is the application's:
      # `route_param :version` on an unversioned API has to reach the endpoint.
      context 'when the route carries no version' do
        let(:route_version) { nil }

        it 'cuts only route_info' do
          expect(request.params).to eq(
            ActiveSupport::HashWithIndifferentAccess.new(a: '123', b: 'xyz', c: 'ccc', version: '123')
          )
        end
      end

      # A capture is a String, so the query's nested Hash under the same name
      # is replaced rather than merged into, as +deep_merge!+ did.
      context 'when the query holds a nested param named like a capture' do
        let(:params) { { a: '123', c: { d: '1' } } }
        let(:route_version) { nil }

        it 'answers the capture' do
          expect(request.params).to eq(ActiveSupport::HashWithIndifferentAccess.new(a: '123', c: 'ccc', version: '123'))
        end
      end
    end

    # Rack memoizes the query params in the env, and that is the hash Grape
    # hands the params builder. A builder that returns its argument would
    # otherwise let the writes that follow -- here the routing args -- reach
    # the env.
    context 'when the params builder returns the hash it was given' do
      let(:passthrough_builder) do
        Class.new(Grape::ParamsBuilder::Base) do
          def self.call(params)
            params
          end
        end
      end

      let(:options) { default_options.merge('grape.routing_args' => { c: 'ccc' }) }
      let(:request) { described_class.new(env, build_params_with: :passthrough) }

      before do
        stub_const('Passthrough', passthrough_builder)
        Grape::ParamsBuilder.register(Passthrough)
      end

      after { Grape::ParamsBuilder.deregister(:passthrough) }

      it 'merges the routing args without touching the query params Rack memoized' do
        expect(request.params).to eq('a' => '123', 'b' => 'xyz', c: 'ccc')
        expect(env[Rack::RACK_REQUEST_QUERY_HASH]).to eq('a' => '123', 'b' => 'xyz')
      end

      # With no query string the builder is handed a Hash every such request
      # shares, so what one request writes must stay out of the next one's.
      context 'when the request has no query string' do
        let(:params) { {} }

        it 'gives each request params of its own' do
          expect(request.params).to eq(c: 'ccc')
          request.params[:d] = 'ddd'

          other_env = Rack::MockRequest.env_for('/', 'grape.routing_args' => { e: 'eee' })
          expect(described_class.new(other_env, build_params_with: :passthrough).params).to eq(e: 'eee')
        end
      end

      # With a body and no query string the builder is handed the form
      # params Rack memoized, as it is the query params without a body.
      context 'when the request has a body and no query string' do
        let(:method) { Rack::POST }

        it 'merges the routing args without touching the form params Rack memoized' do
          expect(request.params).to eq('a' => '123', 'b' => 'xyz', c: 'ccc')
          expect(request.POST).to eq('a' => '123', 'b' => 'xyz')
        end
      end
    end

    # Rack is not asked to parse a query string that is not there.
    context 'when the request has no query string' do
      let(:params) { {} }
      let(:options) { default_options.merge('grape.routing_args' => { c: 'ccc' }) }

      it 'returns the routing args alone' do
        expect(request.params).to eq(ActiveSupport::HashWithIndifferentAccess.new(c: 'ccc'))
      end

      it 'leaves the query params for Rack to answer' do
        request.params

        expect(request.GET).to eq({})
      end

      it 'returns the routing args alone when the env holds no QUERY_STRING' do
        env.delete(Rack::QUERY_STRING)

        expect(request.params).to eq(ActiveSupport::HashWithIndifferentAccess.new(c: 'ccc'))
      end

      context 'when build_params_with: :hash is specified' do
        let(:request) { described_class.new(env, build_params_with: :hash) }

        it 'returns the routing args alone' do
          expect(request.params).to eq(c: 'ccc')
        end
      end
    end

    # Rack reads a form body whatever the method says, so the params of a GET
    # that sends one are still the query params merged with it.
    context 'when a GET carries a form body' do
      let(:env) do
        Rack::MockRequest.env_for('/?a=query', method: Rack::GET, input: 'b=body',
                                               'CONTENT_TYPE' => 'application/x-www-form-urlencoded')
      end

      it 'merges the form params into the query params' do
        expect(request.params).to eq(ActiveSupport::HashWithIndifferentAccess.new('a' => 'query', 'b' => 'body'))
      end
    end

    # Without a query string there is nothing to merge the form params with.
    context 'when a body comes with no query string' do
      let(:method) { Rack::POST }
      let(:options) { default_options.merge('grape.routing_args' => { c: 'ccc' }) }

      it 'returns the form params and the routing args' do
        expect(request.params).to eq(ActiveSupport::HashWithIndifferentAccess.new(a: '123', b: 'xyz', c: 'ccc'))
      end

      context 'when build_params_with: :hash is specified' do
        let(:request) { described_class.new(env, build_params_with: :hash) }

        it 'returns them symbolized' do
          expect(request.params).to eq(a: '123', b: 'xyz', c: 'ccc')
        end
      end

      context 'when the body names one key as both a value and a hash' do
        let(:env) do
          Rack::MockRequest.env_for('/', method: Rack::POST, input: 'x[y]=1&x[y]z=2', 'CONTENT_TYPE' => 'application/x-www-form-urlencoded')
        end

        it 'raises a Grape::Exceptions::RequestError' do
          expect { request.params }.to raise_error(Grape::Exceptions::RequestError)
        end
      end
    end

    context 'when the query string is nested deeper than Rack parses' do
      let(:env) { Rack::MockRequest.env_for("/?foo#{'[a]' * Rack::Utils.param_depth_limit}=bar") }

      it 'raises a Grape::Exceptions::RequestError' do
        expect { request.params }.to raise_error(Grape::Exceptions::RequestError)
      end
    end

    context 'when the query string names one key as both a value and a hash' do
      let(:env) { Rack::MockRequest.env_for('/?x[y]=1&x[y]z=2') }

      it 'raises a Grape::Exceptions::RequestError' do
        expect { request.params }.to raise_error(Grape::Exceptions::RequestError)
      end
    end

    # The errors below are raised while a body is parsed, so the request
    # carries one: Grape only asks Rack for form params when it does.
    context 'when reading the form params raises an EOFError' do
      let(:method) { Rack::POST }

      before { allow(request).to receive(:POST).and_raise(EOFError) }

      it 'raises a Grape::Exceptions::RequestError' do
        expect { request.params }.to raise_error(Grape::Exceptions::RequestError)
      end
    end

    context 'when reading the form params raises a custom error that includes Rack::BadRequest' do
      let(:method) { Rack::POST }
      let(:custom_rack_error) do
        Class.new(StandardError) { include Rack::BadRequest }
      end

      before { allow(request).to receive(:POST).and_raise(custom_rack_error) }

      it 'raises a Grape::Exceptions::RequestError' do
        expect { request.params }.to raise_error(Grape::Exceptions::RequestError)
      end
    end
  end

  describe '#headers' do
    let(:options) do
      default_options.merge(request_headers)
    end

    describe 'with http headers in env' do
      let(:request_headers) do
        {
          'HTTP_X_GRAPE_IS_COOL' => 'yeah'
        }
      end
      let(:x_grape_is_cool_header) do
        'x-grape-is-cool'
      end

      it 'cuts HTTP_ prefix and capitalizes header name words' do
        expect(request.headers).to eq(x_grape_is_cool_header => 'yeah')
      end
    end

    describe 'with non-HTTP_* stuff in env' do
      let(:request_headers) do
        {
          'HTP_X_GRAPE_ENTITY_TOO' => 'but now we are testing Grape'
        }
      end

      it 'does not include them' do
        expect(request.headers).to eq({})
      end
    end

    describe 'with symbolic header names' do
      let(:request_headers) do
        {
          HTTP_GRAPE_LIKES_SYMBOLIC: 'it is true'
        }
      end
      let(:env) do
        default_env.merge(request_headers)
      end
      let(:grape_likes_symbolic_header) do
        'grape-likes-symbolic'
      end

      it 'converts them to string' do
        expect(request.headers).to eq(grape_likes_symbolic_header => 'it is true')
      end
    end
  end
end
