# frozen_string_literal: true

describe Grape::Exceptions::RequestError do
  describe '#initialize' do
    context 'when raised inside a rescue block' do
      it 'captures the current exception message' do
        error = begin
          raise 'boom'
        rescue RuntimeError
          described_class.new
        end
        expect(error.message).to eq('boom')
      end
    end

    context 'when there is no current exception' do
      it 'has no message from a prior exception' do
        # $ERROR_INFO ($!) is read-only and only set by an active rescue, so
        # simulate "no exception" the same way: outside any rescue block.
        # `StandardError#message` defaults to the class name when no message
        # was given, so this pins the $ERROR_INFO&.message safe-nav's nil case.
        expect(described_class.new.message).to eq(described_class.name)
      end
    end

    it 'defaults status to 400' do
      expect(described_class.new.status).to eq(400)
    end

    it 'accepts a custom status' do
      expect(described_class.new(status: 422).status).to eq(422)
    end
  end
end
