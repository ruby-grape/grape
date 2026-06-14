# frozen_string_literal: true

describe Grape::Validations::ValidationsSpec do
  describe '.from' do
    it 'leaves the input hash untouched' do
      raw = { type: Integer, presence: { value: true, message: nil }, length: { min: 1 } }
      original = raw.dup
      described_class.from(raw)
      expect(raw).to eq(original)
    end

    it 'accepts a frozen input hash without raising' do
      raw = { type: Integer, presence: { value: true, message: nil } }.freeze
      expect { described_class.from(raw) }.not_to raise_error
    end

    it 'raises when both :type and :types are supplied' do
      expect { described_class.from(type: Integer, types: [String, Integer]) }
        .to raise_error(ArgumentError, ':type may not be supplied with :types')
    end
  end

  describe 'coerce parsing' do
    it 'extracts a plain :type into coerce_type' do
      spec = described_class.from(type: Integer)
      expect(spec.coerce_type).to eq(Integer)
      expect(spec.coerce_message).to be_nil
    end

    it 'extracts the value/message form of :type' do
      spec = described_class.from(type: { value: Integer, message: 'must be int' })
      expect(spec.coerce_type).to eq(Integer)
      expect(spec.coerce_message).to eq('must be int')
    end

    it 'wraps a multiple type from :type in a VariantCollectionCoercer' do
      multi_spec = described_class.from(type: [Integer, String])
      expect(multi_spec.coerce_type).to be_a(Grape::Validations::Types::VariantCollectionCoercer)
      expect(multi_spec.coerce_type.to_s).to eq('Array[Integer, String]')
      expect(multi_spec.coerce_method).to be_nil
    end

    it 'wraps a Set multiple type from :type in a VariantCollectionCoercer' do
      multi_spec = described_class.from(type: Set[Integer, String])
      expect(multi_spec.coerce_type).to be_a(Grape::Validations::Types::VariantCollectionCoercer)
      expect(multi_spec.coerce_type.to_s).to eq('Set[Integer, String]')
      expect(multi_spec.coerce_method).to be_nil
    end

    it 'extracts :types as a plain coerce list' do
      spec = described_class.from(types: [Integer, String])
      expect(spec.coerce_type).to eq([Integer, String])
      expect(spec.coerce_type.to_s).to eq('[Integer, String]')
    end
  end

  describe 'shared opts' do
    it 'exposes allow_blank and fail_fast as a frozen hash' do
      spec = described_class.from(allow_blank: false, fail_fast: true)
      expect(spec.shared_opts).to eq(allow_blank: false, fail_fast: true)
      expect(spec.shared_opts).to be_frozen
    end

    it 'unwraps the value/message form of allow_blank' do
      spec = described_class.from(allow_blank: { value: false, message: 'no blanks' })
      expect(spec.shared_opts[:allow_blank]).to be(false)
    end

    it 'defaults fail_fast to false when absent' do
      spec = described_class.from({})
      expect(spec.shared_opts[:fail_fast]).to be(false)
    end
  end

  describe 'required?' do
    it 'is true when :presence is set to a truthy value' do
      expect(described_class.from(presence: { value: true })).to be_required
    end

    it 'is false when :presence is absent' do
      expect(described_class.from({})).not_to be_required
    end

    it 'is false when :presence is explicitly false' do
      expect(described_class.from(presence: false)).not_to be_required
    end
  end

  describe 'validator_entries' do
    it 'excludes spec-consumed keys' do
      spec = described_class.from(
        type: Integer,
        presence: { value: true },
        message: 'oops',
        fail_fast: true,
        desc: 'foo',
        regexp: /\d+/,
        values: [1, 2, 3]
      )
      expect(spec.validator_entries.keys).to contain_exactly(:regexp, :values)
    end

    it 'keeps :allow_blank and :length even though they have other roles' do
      spec = described_class.from(allow_blank: false, length: { min: 1 })
      expect(spec.validator_entries.keys).to contain_exactly(:allow_blank, :length)
    end

    it 'excludes documentation-only keys' do
      spec = described_class.from(as: :other, required: true, format: :json)
      expect(spec.validator_entries).to be_empty
    end
  end
end
