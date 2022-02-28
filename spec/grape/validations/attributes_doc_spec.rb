# frozen_string_literal: true

describe Grape::Validations::ParamsScope::AttributesDoc do
  shared_examples 'an optional doc attribute' do |attr|
    it 'does not mention it' do
      expected_opts.delete(attr)
      validations.delete(attr)

      expect(subject.first['nested[engine_age]']).not_to have_key(attr)
    end
  end

  let(:api) { Class.new(Grape::API::Instance) }
  let(:scope) do
    params = nil
    api_instance = api

    # just to get nested params
    Grape::Validations::ParamsScope.new(type: Hash, api: api) do
      params = Grape::Validations::ParamsScope.new(element: 'nested',
                                                   type: Hash,
                                                   api: api_instance,
                                                   parent: self)
    end

    params
  end

  let(:validations) do
    {
      presence: true,
      desc: 'Age of...',
      documentation: 'Age is...',
      default: 1
    }
  end

  let(:doc) { described_class.new(api, scope) }

  describe '#extract_details' do
    subject { doc.extract_details(validations) }

    it 'cleans up doc attrs needed for documentation only' do
      subject

      expect(validations[:desc]).to be_nil
      expect(validations[:documentation]).to be_nil
    end

    it 'does not clean up doc attrs mandatory for validators' do
      subject

      expect(validations[:presence]).not_to be_nil
      expect(validations[:default]).not_to be_nil
    end

    it 'tells when attributes are required' do
      subject

      expect(doc.required).to be_truthy
    end
  end

  describe '#document' do
    subject do
      doc.extract_details validations
      doc.document attrs
    end

    let(:attrs) { %w[engine_age car_age] }
    let(:valid_values) { [1, 3, 5, 8] }

    let!(:expected_opts) do
      {
        required: true,
        desc: validations[:desc],
        documentation: validations[:documentation],
        default: validations[:default],
        type: 'Integer',
        values: valid_values
      }
    end

    before do
      doc.type = Integer
      doc.values = valid_values
    end

    context 'documentation is enabled' do
      subject do
        super()
        api.namespace_stackable(:params)
      end

      it 'documents attributes' do
        expect(subject.first).to eq('nested[engine_age]' => expected_opts,
                                    'nested[car_age]' => expected_opts)
      end

      it_behaves_like 'an optional doc attribute', :default
      it_behaves_like 'an optional doc attribute', :documentation
      it_behaves_like 'an optional doc attribute', :desc
      it_behaves_like 'an optional doc attribute', :type do
        before { doc.type = nil }
      end
      it_behaves_like 'an optional doc attribute', :values do
        before { doc.values = nil }
      end

      context 'false as a default value' do
        before { validations[:default] = false }

        it 'is still documented' do
          doc = subject.first['nested[engine_age]']

          expect(doc).to have_key(:default)
          expect(doc[:default]).to be(false)
        end
      end

      context 'nil as a default value' do
        before { validations[:default] = nil }

        it 'is still documented' do
          doc = subject.first['nested[engine_age]']

          expect(doc).to have_key(:default)
          expect(doc[:default]).to be_nil
        end
      end

      context 'the description key instead of desc' do
        let!(:desc) { validations.delete(:desc) }

        before { validations[:description] = desc }

        it 'adds the given description' do
          expect(subject.first['nested[engine_age]'][:desc]).to eq(desc)
        end
      end
    end

    context 'documentation is disabled' do
      before { api.namespace_inheritable :do_not_document, true }

      it 'does not document attributes' do
        subject

        expect(api.namespace_stackable(:params)).to eq([])
      end
    end
  end
end
