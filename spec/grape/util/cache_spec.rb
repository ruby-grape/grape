# frozen_string_literal: true

RSpec.describe Grape::Util::Cache do
  describe 'synchronized lookup' do
    it 'computes each key once and returns consistent values across threads' do
      # The default block runs while the monitor is held, so this plain
      # counter is race-free by construction.
      computations = []
      cache_class = Class.new(described_class) do
        define_method(:initialize) do
          super()
          @cache = Hash.new do |h, key|
            computations << key
            h[key] = "computed-#{key}"
          end
        end
      end

      results = Array.new(8) { Thread.new { cache_class.instance['k'] } }.map(&:value)

      expect(results).to all(eq('computed-k'))
      expect(computations).to eq(['k'])
    end

    it 'supports reentrant lookups from within a default block' do
      # Types::CoercerCache re-enters itself: a multiple-type coercer builds
      # its member coercers through Types.build_coercer, which lands in the
      # same cache. A non-reentrant lock would deadlock here.
      expect(Grape::Validations::Types.build_coercer([Integer, Float, String])).to be_frozen
    end
  end

  # Layer-1 thread-safety invariant: every Grape::Util::Cache is written only
  # while an API is defined and compiled — never at request time. Requests
  # against shared, unsynchronized-read caches are safe *because* they are
  # read-only; this pins that property. It would have caught the pre-#2817
  # ArrayCoercer seeding DryTypes::ParamsCache on the first request.
  describe 'boot-only growth' do
    let(:app) do
      Class.new(Grape::API) do
        format :json

        params do
          requires :id, type: Integer
          optional :ids, type: Array[Integer]
          optional :tags, type: Set[Integer]
          optional :multi, type: [Integer, String]
          optional :state, type: String, values: %w[a b], default: 'a'
        end
        get('/lookup') { 'ok' }

        params do
          requires :doc, type: JSON do
            requires :name, type: String
          end
          optional :variant, type: Hash, oneof: [proc { requires :x, type: Integer }]
        end
        post('/nested') { 'ok' }
      end
    end

    it 'no cache gains keys after the API is compiled' do
      # Boot fully — definition already happened (params blocks ran when the
      # class body evaluated); compile! builds routes, patterns and the
      # router, which warms the remaining caches.
      app.compile!
      before = described_class.subclasses.to_h { |cache| [cache, cache.cache.keys.dup] }

      # First-ever requests happen only now, so any first-request cache write
      # shows up as growth: valid, invalid, wrong-shape, unmatched-path and
      # unrouted-method traffic.
      mr = Rack::MockRequest.new(app)
      mr.get('/lookup?id=1&ids[]=2&tags[]=3&multi[]=4&state=a')
      mr.get('/lookup?id=nope&multi[]=x')
      mr.post('/nested', input: '{"doc":{"name":"n"},"variant":{"x":1}}', 'CONTENT_TYPE' => 'application/json')
      mr.post('/nested', input: '{"doc":["wrong shape"],"variant":{"y":2}}', 'CONTENT_TYPE' => 'application/json')
      mr.get('/unmatched')
      mr.request('OPTIONS', '/lookup')
      mr.request('PATCH', '/lookup?id=1')

      described_class.subclasses.each do |cache|
        expect(cache.cache.keys).to match_array(before.fetch(cache, [])),
                                    "#{cache} gained keys at request time"
      end
    end
  end
end
