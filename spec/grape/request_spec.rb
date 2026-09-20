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
    context 'when rack_params raises an EOFError' do
      let(:method) { Rack::POST }

      before { allow(request).to receive(:rack_params).and_raise(EOFError) }

      it 'raises a Grape::Exceptions::RequestError' do
        expect { request.params }.to raise_error(Grape::Exceptions::RequestError)
      end
    end

    # Rack 3 introduced Rack::BadRequest as a marker module included by all bad request
    # exception classes, so a single `rescue Rack::BadRequest` covers them all.
    # On Rack 2, there is no such module and each exception class must be tested individually.
    if defined?(Rack::BadRequest)
      context 'when rack_params raises a custom error that includes Rack::BadRequest' do
        let(:method) { Rack::POST }
        let(:custom_rack_error) do
          Class.new(StandardError) { include Rack::BadRequest }
        end

        before { allow(request).to receive(:rack_params).and_raise(custom_rack_error) }

        it 'raises a Grape::Exceptions::RequestError' do
          expect { request.params }.to raise_error(Grape::Exceptions::RequestError)
        end
      end
    else
      context 'when rack_params raises a Rack::Multipart::MultipartPartLimitError' do
        let(:method) { Rack::POST }

        before { allow(request).to receive(:rack_params).and_raise(Rack::Multipart::MultipartPartLimitError) }

        it 'raises a Grape::Exceptions::RequestError' do
          expect { request.params }.to raise_error(Grape::Exceptions::RequestError)
        end
      end

      context 'when rack_params raises a Rack::Multipart::MultipartTotalPartLimitError' do
        let(:method) { Rack::POST }

        before { allow(request).to receive(:rack_params).and_raise(Rack::Multipart::MultipartTotalPartLimitError) }

        it 'raises a Grape::Exceptions::RequestError' do
          expect { request.params }.to raise_error(Grape::Exceptions::RequestError)
        end
      end

      context 'when rack_params raises a Rack::Utils::ParameterTypeError' do
        let(:method) { Rack::POST }

        before { allow(request).to receive(:rack_params).and_raise(Rack::Utils::ParameterTypeError) }

        it 'raises a Grape::Exceptions::RequestError' do
          expect { request.params }.to raise_error(Grape::Exceptions::RequestError)
        end
      end

      context 'when rack_params raises a Rack::Utils::InvalidParameterError' do
        let(:method) { Rack::POST }

        before { allow(request).to receive(:rack_params).and_raise(Rack::Utils::InvalidParameterError) }

        it 'raises a Grape::Exceptions::RequestError' do
          expect { request.params }.to raise_error(Grape::Exceptions::RequestError)
        end
      end

      context 'when rack_params raises a Rack::QueryParser::ParamsTooDeepError' do
        let(:method) { Rack::POST }

        before { allow(request).to receive(:rack_params).and_raise(Rack::QueryParser::ParamsTooDeepError) }

        it 'raises a Grape::Exceptions::RequestError' do
          expect { request.params }.to raise_error(Grape::Exceptions::RequestError)
        end
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
