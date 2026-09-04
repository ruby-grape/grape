# frozen_string_literal: true

describe Grape::Router::BaseRoute do
  let(:pattern) { instance_double(Grape::Router::Pattern) }

  describe '#initialize' do
    context 'when options is a plain Hash' do
      subject(:route) { described_class.new(pattern, { foo: 'bar' }) }

      it 'wraps it in an ActiveSupport::OrderedOptions' do
        expect(route.options).to be_a(ActiveSupport::OrderedOptions)
      end

      it 'reads back the given options' do
        expect(route.options[:foo]).to eq('bar')
      end
    end

    context 'when options is already an ActiveSupport::OrderedOptions' do
      subject(:route) { described_class.new(pattern, options) }

      let(:options) { ActiveSupport::OrderedOptions.new.update(foo: 'bar') }

      it 'uses it as-is, without wrapping it again' do
        expect(route.options).to equal(options)
      end
    end
  end
end
