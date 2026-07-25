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
end
