# frozen_string_literal: true

describe Grape::Exceptions::ErrorResponse do
  describe '#initialize' do
    it 'accepts all known fields and exposes them as readers' do
      payload = described_class.new(
        status: 422,
        message: 'boom',
        headers: { 'X-Foo' => 'bar' },
        backtrace: ['line 1'],
        original_exception: StandardError.new('inner')
      )

      expect(payload.status).to eq(422)
      expect(payload.message).to eq('boom')
      expect(payload.headers).to eq('X-Foo' => 'bar')
      expect(payload.backtrace).to eq(['line 1'])
      expect(payload.original_exception).to be_a(StandardError)
    end

    it 'defaults all fields to nil' do
      payload = described_class.new

      expect(payload.status).to be_nil
      expect(payload.message).to be_nil
      expect(payload.headers).to be_nil
      expect(payload.backtrace).to be_nil
      expect(payload.original_exception).to be_nil
    end
  end

  describe '#to_s' do
    it 'renders status, message, and headers in a readable form' do
      headers = { 'X-Foo' => 'bar' }
      payload = described_class.new(status: 422, message: 'boom', headers:)

      expect(payload.to_s).to eq(%(#<Grape::Exceptions::ErrorResponse status=422 message="boom" headers=#{headers.inspect}>))
    end
  end

  describe '#==' do
    let(:exception) { StandardError.new('inner') }
    let(:attrs) { { status: 422, message: 'boom', headers: { 'X-Foo' => 'bar' }, backtrace: ['line 1'], original_exception: exception } }
    let(:payload) { described_class.new(**attrs) }
    let(:twin) { described_class.new(**attrs) }

    it 'is equal when every attribute matches' do
      expect(payload).to eq(twin)
    end

    it 'is not equal when any attribute differs' do
      expect(payload).not_to eq(described_class.new(**attrs, status: 500))
    end

    it 'is not equal to a non-ErrorResponse with the same shape' do
      expect(described_class.new(status: 422)).not_to eq(Object.new)
    end

    it 'returns the same hash for equal instances' do
      expect(payload.hash).to eq(twin.hash)
    end
  end

  describe '.from_exception' do
    it 'extracts status, message, headers, and backtrace from a Grape exception' do
      exception = Grape::Exceptions::Base.new(status: 418, message: 'teapot', headers: { 'X-T' => '1' })
      payload = described_class.from_exception(exception)

      expect(payload.status).to eq(418)
      expect(payload.message).to eq('teapot')
      expect(payload.headers).to eq('X-T' => '1')
      expect(payload.original_exception).to eq(exception)
    end
  end

  describe '.coerce' do
    it 'returns the input unchanged when it is already an ErrorResponse' do
      input = described_class.new(status: 500)

      expect(described_class.coerce(input)).to equal(input)
    end

    it 'wraps a Grape exception via from_exception' do
      exception = Grape::Exceptions::Base.new(status: 404, message: 'gone')
      payload = described_class.coerce(exception)

      expect(payload).to be_a(described_class)
      expect(payload.status).to eq(404)
      expect(payload.message).to eq('gone')
      expect(payload.original_exception).to eq(exception)
    end

    it 'builds a new ErrorResponse from a Hash, picking only known keys' do
      payload = described_class.coerce(status: 503, message: 'down', irrelevant: 'ignored')

      expect(payload.status).to eq(503)
      expect(payload.message).to eq('down')
    end

    it 'returns an empty ErrorResponse for unsupported input' do
      payload = described_class.coerce(nil)

      expect(payload).to be_a(described_class)
      expect(payload.status).to be_nil
    end
  end
end
