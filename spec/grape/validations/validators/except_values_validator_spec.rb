# frozen_string_literal: true

describe Grape::Validations::Validators::ExceptValuesValidator do
  describe 'IncompatibleOptionValues' do
    subject { api }

    context 'when a default value is set' do
      let(:api) do
        ev = except_values
        dv = default_value
        Class.new(Grape::API) do
          params do
            optional :type, except_values: ev, default: dv
          end
        end
      end

      context 'when default value is in exclude' do
        let(:except_values) { 1..10 }
        let(:default_value) { except_values.to_a.sample }

        it 'raises IncompatibleOptionValues' do
          expect { subject }.to raise_error Grape::Exceptions::IncompatibleOptionValues
        end
      end

      context 'when default array has excluded values' do
        let(:except_values) { 1..10 }
        let(:default_value) { [8, 9, 10] }

        it 'raises IncompatibleOptionValues' do
          expect { subject }.to raise_error Grape::Exceptions::IncompatibleOptionValues
        end
      end
    end

    context 'when type is incompatible' do
      let(:api) do
        Class.new(Grape::API) do
          params do
            optional :type, except_values: 1..10, type: Symbol
          end
        end
      end

      it 'raises IncompatibleOptionValues' do
        expect { subject }.to raise_error Grape::Exceptions::IncompatibleOptionValues
      end
    end
  end

  {
    req_except: {
      requires: { except_values: %w[invalid-type1 invalid-type2 invalid-type3] },
      tests: [
        { value: 'invalid-type1', rc: 400, body: { error: 'type has a value not allowed' }.to_json },
        { value: 'invalid-type3', rc: 400, body: { error: 'type has a value not allowed' }.to_json },
        { value: 'valid-type', rc: 200, body: { type: 'valid-type' }.to_json }
      ]
    },
    req_except_hash: {
      requires: { except_values: { value: %w[invalid-type1 invalid-type2 invalid-type3] } },
      tests: [
        { value: 'invalid-type1', rc: 400, body: { error: 'type has a value not allowed' }.to_json },
        { value: 'invalid-type3', rc: 400, body: { error: 'type has a value not allowed' }.to_json },
        { value: 'valid-type', rc: 200, body: { type: 'valid-type' }.to_json }
      ]
    },
    req_except_custom_message: {
      requires: { except_values: { value: %w[invalid-type1 invalid-type2 invalid-type3], message: 'is not allowed' } },
      tests: [
        { value: 'invalid-type1', rc: 400, body: { error: 'type is not allowed' }.to_json },
        { value: 'invalid-type3', rc: 400, body: { error: 'type is not allowed' }.to_json },
        { value: 'valid-type', rc: 200, body: { type: 'valid-type' }.to_json }
      ]
    },
    req_except_no_value: {
      requires: { except_values: { message: 'is not allowed' } },
      tests: [
        { value: 'invalid-type1', rc: 200, body: { type: 'invalid-type1' }.to_json }
      ]
    },
    req_except_empty: {
      requires: { except_values: [] },
      tests: [
        { value: 'invalid-type1', rc: 200, body: { type: 'invalid-type1' }.to_json }
      ]
    },
    req_except_lambda: {
      requires: { except_values: -> { %w[invalid-type1 invalid-type2 invalid-type3 invalid-type4] } },
      tests: [
        { value: 'invalid-type1', rc: 400, body: { error: 'type has a value not allowed' }.to_json },
        { value: 'invalid-type4', rc: 400, body: { error: 'type has a value not allowed' }.to_json },
        { value: 'valid-type', rc: 200, body: { type: 'valid-type' }.to_json }
      ]
    },
    req_except_lambda_custom_message: {
      requires: { except_values: { value: -> { %w[invalid-type1 invalid-type2 invalid-type3 invalid-type4] }, message: 'is not allowed' } },
      tests: [
        { value: 'invalid-type1', rc: 400, body: { error: 'type is not allowed' }.to_json },
        { value: 'invalid-type4', rc: 400, body: { error: 'type is not allowed' }.to_json },
        { value: 'valid-type', rc: 200, body: { type: 'valid-type' }.to_json }
      ]
    },
    opt_except_default: {
      optional: { except_values: %w[invalid-type1 invalid-type2 invalid-type3], default: 'valid-type2' },
      tests: [
        { value: 'invalid-type1', rc: 400, body: { error: 'type has a value not allowed' }.to_json },
        { value: 'invalid-type3', rc: 400, body: { error: 'type has a value not allowed' }.to_json },
        { value: 'valid-type', rc: 200, body: { type: 'valid-type' }.to_json },
        { rc: 200, body: { type: 'valid-type2' }.to_json }
      ]
    },
    opt_except_lambda_default: {
      optional: { except_values: -> { %w[invalid-type1 invalid-type2 invalid-type3] }, default: 'valid-type2' },
      tests: [
        { value: 'invalid-type1', rc: 400, body: { error: 'type has a value not allowed' }.to_json },
        { value: 'invalid-type3', rc: 400, body: { error: 'type has a value not allowed' }.to_json },
        { value: 'valid-type', rc: 200, body: { type: 'valid-type' }.to_json },
        { rc: 200, body: { type: 'valid-type2' }.to_json }
      ]
    },
    req_except_type_coerce: {
      requires: { type: Integer, except_values: [10, 11] },
      tests: [
        { value: 'invalid-type1', rc: 400, body: { error: 'type is invalid' }.to_json },
        { value: 11, rc: 400, body: { error: 'type has a value not allowed' }.to_json },
        { value: '11', rc: 400, body: { error: 'type has a value not allowed' }.to_json },
        { value: '3', rc: 200, body: { type: 3 }.to_json },
        { value: 3, rc: 200, body: { type: 3 }.to_json }
      ]
    },
    opt_except_type_coerce_default: {
      optional: { type: Integer, except_values: [10, 11], default: 12 },
      tests: [
        { value: 'invalid-type1', rc: 400, body: { error: 'type is invalid' }.to_json },
        { value: 10, rc: 400, body: { error: 'type has a value not allowed' }.to_json },
        { value: '3', rc: 200, body: { type: 3 }.to_json },
        { value: 3, rc: 200, body: { type: 3 }.to_json },
        { rc: 200, body: { type: 12 }.to_json }
      ]
    },
    opt_except_array_type_coerce_default: {
      optional: { type: Array[Integer], except_values: [10, 11], default: 12 },
      tests: [
        { value: 'invalid-type1', rc: 400, body: { error: 'type is invalid' }.to_json },
        { value: 10, rc: 400, body: { error: 'type is invalid' }.to_json },
        { value: [10], rc: 400, body: { error: 'type has a value not allowed' }.to_json },
        { value: ['3'], rc: 200, body: { type: [3] }.to_json },
        { value: [3], rc: 200, body: { type: [3] }.to_json },
        { rc: 200, body: { type: 12 }.to_json }
      ]
    },
    req_except_range: {
      optional: { type: Integer, except_values: 10..12 },
      tests: [
        { value: 11, rc: 400, body: { error: 'type has a value not allowed' }.to_json },
        { value: 13, rc: 200, body: { type: 13 }.to_json }
      ]
    }
  }.each do |path, param_def|
    param_def[:tests].each do |t|
      describe "when #{path}" do
        let(:app) do
          Class.new(Grape::API) do
            default_format :json
            params do
              requires :type, param_def[:requires] if param_def.key? :requires
              optional :type, param_def[:optional] if param_def.key? :optional
            end
            get path do
              { type: params[:type] }
            end
          end
        end

        let(:body) do
          {}.tap do |body|
            body[:type] = t[:value] if t.key? :value
          end
        end

        before do
          get path.to_s, **body
        end

        it "returns body #{t[:body]} with status #{t[:rc]}" do
          expect(last_response.status).to eq t[:rc]
          expect(last_response.body).to eq t[:body]
        end
      end
    end
  end
end
