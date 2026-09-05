# frozen_string_literal: true

describe Grape::Middleware::Filter do
  let(:before_proc) { -> {} }
  let(:after_proc) { -> {} }
  let(:app) { ->(_env) { [200, {}, ['Hi there.']] } }
  let(:middleware) { described_class.new(app, before: before_proc, after: after_proc) }

  describe '#before' do
    it 'instance_evals the :before option against the app' do
      expect(app).to receive(:instance_eval) do |&block|
        expect(block).to eq(before_proc)
      end
      middleware.before
    end

    context 'when no :before option is given' do
      let(:middleware) { described_class.new(app) }

      it 'does nothing' do
        expect(app).not_to receive(:instance_eval)
        middleware.before
      end
    end
  end

  describe '#after' do
    it 'instance_evals the :after option against the app' do
      expect(app).to receive(:instance_eval) do |&block|
        expect(block).to eq(after_proc)
      end
      middleware.after
    end

    context 'when no :after option is given' do
      let(:middleware) { described_class.new(app) }

      it 'does nothing' do
        expect(app).not_to receive(:instance_eval)
        middleware.after
      end
    end
  end
end
