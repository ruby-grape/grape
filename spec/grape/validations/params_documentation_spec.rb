# frozen_string_literal: true

describe Grape::Validations::ParamsDocumentation do
  subject { klass.new(api_double) }

  let(:api_double) do
    Class.new do
      include Grape::DSL::Settings
    end.new
  end

  let(:klass) do
    Class.new do
      include Grape::Validations::ParamsDocumentation

      attr_accessor :api

      def initialize(api)
        @api = api
      end

      def full_name(name)
        "full_name_#{name}"
      end
    end
  end

  describe '#document_params' do
    it 'stores documented params with all details' do
      attrs = %i[foo bar]
      validations = {
        presence: true,
        default: 42,
        length: { min: 1, max: 10 },
        desc: 'A foo',
        documentation: { note: 'doc' }
      }
      type = Integer
      values = [1, 2, 3]
      except_values = [4, 5, 6]
      subject.document_params(attrs, validations.dup, type, values, except_values)
      expect(api_double.inheritable_setting.namespace_stackable[:params].first.keys).to include('full_name_foo', 'full_name_bar')
      expect(api_double.inheritable_setting.namespace_stackable[:params].first['full_name_foo']).to include(
        required: true,
        type: 'Integer',
        values: [1, 2, 3],
        except_values: [4, 5, 6],
        default: 42,
        min_length: 1,
        max_length: 10,
        desc: 'A foo',
        documentation: { note: 'doc' }
      )
    end

    context 'when do_not_document is set' do
      let(:validations) do
        { desc: 'desc', description: 'description', documentation: { foo: 'bar' }, another_param: 'test' }
      end

      before do
        api_double.inheritable_setting.namespace_inheritable[:do_not_document] = true
      end

      it 'removes desc, description, and documentation' do
        subject.document_params([:foo], validations)
        expect(validations).to eq({ another_param: 'test' })
      end
    end

    context 'when validation is empty' do
      let(:validations) do
        {}
      end

      it 'does not raise an error' do
        expect { subject.document_params([:foo], validations) }.not_to raise_error
        expect(api_double.inheritable_setting.namespace_stackable[:params].first['full_name_foo']).to eq({ required: false })
      end
    end

    context 'when desc is not present' do
      let(:validations) do
        { description: 'desc2' }
      end

      it 'uses description if desc is not present' do
        subject.document_params([:foo], validations)
        expect(api_double.inheritable_setting.namespace_stackable[:params].first['full_name_foo'][:desc]).to eq('desc2')
      end
    end

    context 'when desc nor description is present' do
      let(:validations) do
        {}
      end

      it 'uses description if desc is not present' do
        subject.document_params([:foo], validations)
        expect(api_double.inheritable_setting.namespace_stackable[:params].first['full_name_foo']).to eq({ required: false })
      end
    end

    context 'when documentation is not present' do
      let(:validations) do
        {}
      end

      it 'does not include documentation' do
        subject.document_params([:foo], validations)
        expect(api_double.inheritable_setting.namespace_stackable[:params].first['full_name_foo']).not_to have_key(:documentation)
      end
    end

    context 'when type is nil' do
      let(:validations) do
        { presence: true }
      end

      it 'sets type as nil' do
        subject.document_params([:foo], validations)
        expect(api_double.inheritable_setting.namespace_stackable[:params].first['full_name_foo'][:type]).to be_nil
      end
    end
  end
end
