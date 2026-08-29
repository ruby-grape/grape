# frozen_string_literal: true

RSpec.describe Grape::Router::Route do
  let(:instance) { described_class.new(endpoint, :get, pattern, options, forward_match:) }
  let(:endpoint) { instance_double(Grape::Endpoint) }
  let(:options) { {} }
  let(:pattern) do
    Grape::Router::Pattern.new(
      origin: '/mounty',
      suffix: '',
      anchor: true,
      params: {},
      version: nil,
      requirements: {}
    )
  end

  describe 'inheritance' do
    subject { described_class.new(endpoint, :get, pattern, options, forward_match: false) }

    it { is_expected.to be_a(Grape::Router::BaseRoute) }
  end

  describe '#regexp_capture_index' do
    subject(:route) { described_class.new(endpoint, :get, pattern, options, forward_match: false) }

    # The reader is called from request-time route matching on instances
    # shared across threads, so it must be assigned during #to_regexp
    # (router compilation), never lazily at read time. Freezing the route
    # proves no ivar is written after compilation.
    it 'is assigned eagerly by #to_regexp and readable on a frozen route' do
      route.to_regexp(3)
      route.freeze
      expect(route.regexp_capture_index).to eq('_3')
    end
  end

  describe 'metadata attributes (namespace, prefix, settings)' do
    subject(:route) do
      described_class.new(endpoint, :get, pattern, options, forward_match: false,
                                                            namespace: '/things', prefix: '/api', settings: { a: 1 })
    end

    it 'exposes them as readers' do
      expect(route.namespace).to eq('/things')
      expect(route.prefix).to eq('/api')
      expect(route.settings).to eq(a: 1)
    end

    it 'does not leak them into the options Hash' do
      %i[namespace prefix settings].each do |key|
        expect(route.options).not_to have_key(key)
      end
    end

    context 'when omitted' do
      subject(:route) { described_class.new(endpoint, :get, pattern, options, forward_match: false) }

      it 'defaults to nil' do
        expect(route.namespace).to be_nil
        expect(route.prefix).to be_nil
        expect(route.settings).to be_nil
      end
    end
  end

  describe 'match parameters delegated to the pattern (version, anchor, requirements)' do
    subject(:route) { described_class.new(endpoint, :get, pattern, options, forward_match: false) }

    let(:pattern) do
      Grape::Router::Pattern.new(origin: '/mounty', suffix: '', anchor: false, params: {}, version: 'v1', requirements: { id: /\d+/ })
    end

    it 'reads them from the pattern' do
      expect(route.version).to eq('v1')
      expect(route.anchor).to be(false)
      expect(route.requirements).to eq(id: /\d+/)
    end
  end

  describe 'description attributes' do
    subject(:route) { described_class.new(endpoint, :get, pattern, options, forward_match: false) }

    let(:options) { { description: 'a route', tags: %w[a b] } }

    it 'reads them from the options Hash' do
      expect(route.description).to eq('a route')
      expect(route.tags).to eq(%w[a b])
    end

    it 'returns nil for a key the description did not set' do
      expect(route.summary).to be_nil
    end
  end

  describe '#default_response' do
    subject(:route) { described_class.new(endpoint, :get, pattern, options, forward_match: false) }

    context 'when the description used the current name' do
      let(:options) { { default_response: { code: 400 } } }

      it 'reads it' do
        expect(route.default_response).to eq(code: 400)
      end
    end

    context 'when the description carries neither' do
      let(:options) { {} }

      it 'returns nil' do
        expect(route.default_response).to be_nil
      end
    end
  end

  # +default+ is also Hash#default, so this one reader cannot be generated as a
  # delegator to the options Hash: the call would answer the Hash's own default
  # value instead of the key.
  describe '#default' do
    subject(:route) { described_class.new(endpoint, :get, pattern, options, forward_match: false) }

    let(:options) { { default_response: { code: 400 } } }

    it 'is deprecated' do
      expect { route.default }.to raise_error(ActiveSupport::DeprecationException, /default_response/)
    end

    it 'answers default_response when deprecations are silenced' do
      Grape.deprecator.silence { expect(route.default).to eq(code: 400) }
    end
  end

  describe '#success and #failure' do
    subject(:route) { described_class.new(endpoint, :get, pattern, options, forward_match: false) }

    context 'when the description used the block DSL names' do
      let(:options) { { entity: Object, http_codes: [[401, 'Unauthorized']] } }

      it 'reads the canonical keys' do
        expect(route.success).to eq(Object)
        expect(route.failure).to eq([[401, 'Unauthorized']])
      end
    end

    context 'when the description was written as keyword options' do
      let(:options) { { success: Object, failure: [[401, 'Unauthorized']] } }

      it 'reads the keys as spelled' do
        expect(route.success).to eq(Object)
        expect(route.failure).to eq([[401, 'Unauthorized']])
      end
    end

    context 'when the description carries neither' do
      let(:options) { {} }

      it 'returns nil' do
        expect(route.success).to be_nil
        expect(route.failure).to be_nil
      end
    end
  end

  describe 'params' do
    let(:pattern) do
      Grape::Router::Pattern.new(origin: '/users/:id', suffix: '', anchor: true,
                                 params: { 'id' => { type: 'Integer' } }, version: nil, requirements: {})
    end

    describe '#params (declared definitions, no input)' do
      subject(:route) do
        described_class.new(endpoint, :get, pattern, options, forward_match: false,
                                                              params: { 'id' => { required: true, type: 'Integer' } })
      end

      it 'merges the declared definitions over the path capture defaults' do
        expect(route.params).to eq('id' => { required: true, type: 'Integer' })
      end

      it 'reads the params keyword, not the options Hash' do
        route = described_class.new(endpoint, :get, pattern, { params: { 'ignored' => {} } },
                                    forward_match: false, params: { 'id' => { required: true } })
        expect(route.params).to eq('id' => { required: true })
      end
    end

    describe '#params_for (extracted values, with input)' do
      subject(:route) { described_class.new(endpoint, :get, pattern, options, forward_match: false) }

      it 'extracts param values from a matched input path' do
        expect(route.params_for('/users/7')).to eq(id: '7')
      end

      it 'returns nil when the input does not match' do
        expect(route.params_for('/nope')).to be_nil
      end
    end
  end

  describe '#match?' do
    subject { instance.match?(input) }

    context 'when forward_match is true' do
      let(:forward_match) { true }

      context 'with the exact origin' do
        let(:input) { '/mounty' }

        it { is_expected.to be_truthy }
      end

      context 'with a subpath under the origin' do
        let(:input) { '/mounty/awesome/deep' }

        it 'matches on the origin prefix' do
          expect(subject).to be_truthy
        end
      end

      context 'with a path outside the origin' do
        let(:input) { '/other' }

        it { is_expected.to be_falsey }
      end

      context 'with a blank input' do
        let(:input) { '' }

        it { is_expected.to be(false) }
      end
    end

    context 'when forward_match is false' do
      let(:forward_match) { false }

      context 'with the exact origin' do
        let(:input) { '/mounty' }

        it { is_expected.to be_truthy }
      end

      context 'with a subpath under the origin' do
        let(:input) { '/mounty/awesome/deep' }

        it 'does not match beyond the anchored pattern' do
          expect(subject).to be_falsey
        end
      end

      context 'with a blank input' do
        let(:input) { '' }

        it { is_expected.to be(false) }
      end
    end
  end
end
