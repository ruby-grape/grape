# frozen_string_literal: true

require 'spec_helper'

describe Grape::Validations::Validators::ExceptValuesValidator do
  before :all do
    ExceptValuesModel = ExceptValuesModel = Class.new do
      DEFAULT_EXCEPTS = %w[invalid-type1 invalid-type2 invalid-type3].freeze
      class << self
        attr_accessor :excepts

        def excepts
          @excepts ||= []
          [DEFAULT_EXCEPTS + @excepts].flatten.uniq
        end
      end
    end
    @app = Class.new(Grape::API) do
      default_format :json

      helpers do
        def generic_response
          { type: params[:type] }
        end
      end

      params do
        requires :type, except_values: ExceptValuesModel.excepts
      end
      get '/req_except' do
        generic_response
      end

      params do
        requires :type, except_values: { value: ExceptValuesModel.excepts }
      end
      get '/req_except_hash' do
        generic_response
      end

      params do
        requires :type, except_values: { value: ExceptValuesModel.excepts, message: 'is not allowed' }
      end
      get '/req_except_custom_message' do
        generic_response
      end

      params do
        requires :type, except_values: { message: 'is not allowed' }
      end
      get '/req_except_no_value' do
        generic_response
      end

      params do
        requires :type, except_values: []
      end
      get '/req_except_empty' do
        generic_response
      end

      params do
        requires :type, except_values: -> { ExceptValuesModel.excepts }
      end
      get '/req_except_lambda' do
        generic_response
      end

      params do
        requires :type, except_values: { value: -> { ExceptValuesModel.excepts }, message: 'is not allowed' }
      end
      get '/req_except_lambda_custom_message' do
        generic_response
      end

      params do
        requires :type, type: Integer, except_values: [10, 11]
      end
      get '/req_except_type_coerce' do
        generic_response
      end

      params do
        requires :type, type: Integer, except_values: [10, 11]
      end
      get '/req_except_type_coerce' do
        generic_response
      end

      params do
        optional :type, except_values: ExceptValuesModel.excepts, default: 'valid-type2'
      end
      get '/opt_except_default' do
        generic_response
      end

      params do
        optional :type, except_values: -> { ExceptValuesModel.excepts }, default: 'valid-type2'
      end
      get '/opt_except_lambda_default' do
        generic_response
      end

      params do
        optional :type, type: Integer, except_values: [10, 11], default: 12
      end
      get '/opt_except_type_coerce_default' do
        generic_response
      end

      params do
        optional :type, type: Array[Integer], except_values: [10, 11], default: 12
      end
      get '/opt_except_array_type_coerce_default' do
        generic_response
      end

      params do
        optional :type, type: Integer, except_values: 10..12
      end
      get '/req_except_range' do
        generic_response
      end
    end
  end

  let(:app) { @app }

  it 'raises IncompatibleOptionValues on a default value in exclude' do
    subject = Class.new(Grape::API)
    expect do
      subject.params do
        optional :type, except_values: ExceptValuesModel.excepts,
                        default: ExceptValuesModel.excepts.sample
      end
    end.to raise_error Grape::Exceptions::IncompatibleOptionValues
  end

  it 'raises IncompatibleOptionValues when a default array has excluded values' do
    subject = Class.new(Grape::API)
    expect do
      subject.params do
        optional :type, type: Array[Integer],
                        except_values: 10..12,
                        default: [8, 9, 10]
      end
    end.to raise_error Grape::Exceptions::IncompatibleOptionValues
  end

  it 'raises IncompatibleOptionValues when type is incompatible with values array' do
    subject = Class.new(Grape::API)
    expect do
      subject.params { optional :type, except_values: %w[valid-type1 valid-type2 valid-type3], type: Symbol }
    end.to raise_error Grape::Exceptions::IncompatibleOptionValues
  end

  let(:app) { @app }

  {
    req_except: {
      tests: [
        { value: 'invalid-type1', rc: 400, body: { error: 'type has a value not allowed' }.to_json },
        { value: 'invalid-type3', rc: 400, body: { error: 'type has a value not allowed' }.to_json },
        { value: 'valid-type', rc: 200, body: { type: 'valid-type' }.to_json }
      ]
    },
    req_except_hash: {
      tests: [
        { value: 'invalid-type1', rc: 400, body: { error: 'type has a value not allowed' }.to_json },
        { value: 'invalid-type3', rc: 400, body: { error: 'type has a value not allowed' }.to_json },
        { value: 'valid-type', rc: 200, body: { type: 'valid-type' }.to_json }
      ]
    },
    req_except_custom_message: {
      tests: [
        { value: 'invalid-type1', rc: 400, body: { error: 'type is not allowed' }.to_json },
        { value: 'invalid-type3', rc: 400, body: { error: 'type is not allowed' }.to_json },
        { value: 'valid-type', rc: 200, body: { type: 'valid-type' }.to_json }
      ]
    },
    req_except_no_value: {
      tests: [
        { value: 'invalid-type1', rc: 200, body: { type: 'invalid-type1' }.to_json }
      ]
    },
    req_except_empty: {
      tests: [
        { value: 'invalid-type1', rc: 200, body: { type: 'invalid-type1' }.to_json }
      ]
    },
    req_except_lambda: {
      add_excepts: ['invalid-type4'],
      tests: [
        { value: 'invalid-type1', rc: 400, body: { error: 'type has a value not allowed' }.to_json },
        { value: 'invalid-type4', rc: 400, body: { error: 'type has a value not allowed' }.to_json },
        { value: 'valid-type', rc: 200, body: { type: 'valid-type' }.to_json }
      ]
    },
    req_except_lambda_custom_message: {
      add_excepts: ['invalid-type4'],
      tests: [
        { value: 'invalid-type1', rc: 400, body: { error: 'type is not allowed' }.to_json },
        { value: 'invalid-type4', rc: 400, body: { error: 'type is not allowed' }.to_json },
        { value: 'valid-type', rc: 200, body: { type: 'valid-type' }.to_json }
      ]
    },
    opt_except_default: {
      tests: [
        { value: 'invalid-type1', rc: 400, body: { error: 'type has a value not allowed' }.to_json },
        { value: 'invalid-type3', rc: 400, body: { error: 'type has a value not allowed' }.to_json },
        { value: 'valid-type', rc: 200, body: { type: 'valid-type' }.to_json },
        { rc: 200, body: { type: 'valid-type2' }.to_json }
      ]
    },
    opt_except_lambda_default: {
      tests: [
        { value: 'invalid-type1', rc: 400, body: { error: 'type has a value not allowed' }.to_json },
        { value: 'invalid-type3', rc: 400, body: { error: 'type has a value not allowed' }.to_json },
        { value: 'valid-type', rc: 200, body: { type: 'valid-type' }.to_json },
        { rc: 200, body: { type: 'valid-type2' }.to_json }
      ]
    },
    req_except_type_coerce: {
      tests: [
        { value: 'invalid-type1', rc: 400, body: { error: 'type is invalid' }.to_json },
        { value: 11, rc: 400, body: { error: 'type has a value not allowed' }.to_json },
        { value: '11', rc: 400, body: { error: 'type has a value not allowed' }.to_json },
        { value: '3', rc: 200, body: { type: 3 }.to_json },
        { value: 3, rc: 200, body: { type: 3 }.to_json }
      ]
    },
    opt_except_type_coerce_default: {
      tests: [
        { value: 'invalid-type1', rc: 400, body: { error: 'type is invalid' }.to_json },
        { value: 10, rc: 400, body: { error: 'type has a value not allowed' }.to_json },
        { value: '3', rc: 200, body: { type: 3 }.to_json },
        { value: 3, rc: 200, body: { type: 3 }.to_json },
        { rc: 200, body: { type: 12 }.to_json }
      ]
    },
    opt_except_array_type_coerce_default: {
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
      tests: [
        { value: 11, rc: 400, body: { error: 'type has a value not allowed' }.to_json },
        { value: 13, rc: 200, body: { type: 13 }.to_json }
      ]
    }
  }.freeze.each_with_index do |(k, v), i|
    v[:tests].each do |t|
      it "#{i}: #{k} - #{t[:value]}" do
        ExceptValuesModel.excepts = v[:add_excepts] if v.key? :add_excepts
        body = {}
        body[:type] = t[:value] if t.key? :value
        get k.to_s, **body
        expect(last_response.status).to eq t[:rc]
        expect(last_response.body).to eq t[:body]
        ExceptValuesModel.excepts = nil
      end
    end
  end
end
