# frozen_string_literal: true

require 'shared/deprecated_class_examples'

describe Grape::Validations do
  describe 'Grape::Validations::Base' do
    let(:deprecated_class) do
      Class.new(Grape::Validations::Base)
    end

    it_behaves_like 'deprecated class'
  end

  describe 'using a custom length validator' do
    subject do
      Class.new(Grape::API) do
        params do
          requires :text, default_length: 140
        end
        get do
          'bacon'
        end
      end
    end

    let(:default_length_validator) do
      Class.new(Grape::Validations::Validators::Base) do
        def validate_param!(attr_name, params)
          @option = params[:max].to_i if params.key?(:max)
          return if params[attr_name].length <= @option

          raise Grape::Exceptions::Validation.new(params: [@scope.full_name(attr_name)], message: "must be at the most #{@option} characters long")
        end
      end
    end
    let(:app) { Rack::Builder.new(subject) }

    before { stub_const('Grape::Validations::Validators::DefaultLengthValidator', default_length_validator) }

    it 'under 140 characters' do
      get '/', text: 'abc'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq 'bacon'
    end

    it 'over 140 characters' do
      get '/', text: 'a' * 141
      expect(last_response.status).to eq 400
      expect(last_response.body).to eq 'text must be at the most 140 characters long'
    end

    it 'specified in the query string' do
      get '/', text: 'a' * 141, max: 141
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq 'bacon'
    end
  end

  describe 'using a custom body-only validator' do
    subject do
      Class.new(Grape::API) do
        params do
          requires :text, in_body: true
        end
        get do
          'bacon'
        end
      end
    end

    let(:in_body_validator) do
      Class.new(Grape::Validations::Validators::PresenceValidator) do
        def validate(request)
          validate!(request.env['api.request.body'])
        end
      end
    end
    let(:app) { Rack::Builder.new(subject) }

    before { stub_const('Grape::Validations::Validators::InBodyValidator', in_body_validator) }

    it 'allows field in body' do
      get '/', text: 'abc'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq 'bacon'
    end

    it 'ignores field in query' do
      get '/', nil, text: 'abc'
      expect(last_response.status).to eq 400
      expect(last_response.body).to eq 'text is missing'
    end
  end

  describe 'using a custom validator with message_key' do
    subject do
      Class.new(Grape::API) do
        params do
          requires :text, with_message_key: true
        end
        get do
          'bacon'
        end
      end
    end

    let(:message_key_validator) do
      Class.new(Grape::Validations::Validators::PresenceValidator) do
        def validate_param!(attr_name, _params)
          raise Grape::Exceptions::Validation.new(params: [@scope.full_name(attr_name)], message: :presence)
        end
      end
    end
    let(:app) { Rack::Builder.new(subject) }

    before { stub_const('Grape::Validations::Validators::WithMessageKeyValidator', message_key_validator) }

    it 'fails with message' do
      get '/', text: 'foobar'
      expect(last_response.status).to eq 400
      expect(last_response.body).to eq 'text is missing'
    end
  end

  describe 'using a custom request/param validator' do
    subject do
      Class.new(Grape::API) do
        params do
          optional :admin_field, type: String, admin: true
          optional :non_admin_field, type: String
          optional :admin_false_field, type: String, admin: false
        end
        get do
          'bacon'
        end
      end
    end

    let(:admin_validator) do
      Class.new(Grape::Validations::Validators::Base) do
        def validate(request)
          # return if the param we are checking was not in request
          # @attrs is a list containing the attribute we are currently validating
          return unless request.params.key? @attrs.first
          # check if admin flag is set to true
          return unless @option

          # check if user is admin or not
          # as an example get a token from request and check if it's admin or not
          raise Grape::Exceptions::Validation.new(params: @attrs, message: 'Can not set Admin only field.') unless request.headers[access_header] == 'admin'
        end

        def access_header
          Grape::Http::Headers.lowercase? ? 'x-access-token' : 'X-Access-Token'
        end
      end
    end

    let(:app) { Rack::Builder.new(subject) }
    let(:x_access_token_header) { Grape::Http::Headers.lowercase? ? 'x-access-token' : 'X-Access-Token' }

    before { stub_const('Grape::Validations::Validators::AdminValidator', admin_validator) }

    it 'fail when non-admin user sets an admin field' do
      get '/', admin_field: 'tester', non_admin_field: 'toaster'
      expect(last_response.status).to eq 400
      expect(last_response.body).to include 'Can not set Admin only field.'
    end

    it 'does not fail when we send non-admin fields only' do
      get '/', non_admin_field: 'toaster'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq 'bacon'
    end

    it 'does not fail when we send non-admin and admin=false fields only' do
      get '/', non_admin_field: 'toaster', admin_false_field: 'test'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq 'bacon'
    end

    it 'does not fail when we send admin fields and we are admin' do
      header x_access_token_header, 'admin'
      get '/', admin_field: 'tester', non_admin_field: 'toaster', admin_false_field: 'test'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq 'bacon'
    end

    it 'fails when we send admin fields and we are not admin' do
      header x_access_token_header, 'user'
      get '/', admin_field: 'tester', non_admin_field: 'toaster', admin_false_field: 'test'
      expect(last_response.status).to eq 400
      expect(last_response.body).to include 'Can not set Admin only field.'
    end
  end

  describe 'using a custom validator with instance variable' do
    let(:validator_type) do
      Class.new(Grape::Validations::Validators::Base) do
        def validate_param!(_attr_name, _params)
          if instance_variable_defined?(:@instance_variable) && @instance_variable
            raise Grape::Exceptions::Validation.new(params: ['params'],
                                                    message: 'This should never happen')
          end
          @instance_variable = true
        end
      end
    end
    let(:app) do
      Class.new(Grape::API) do
        params do
          optional :param_to_validate, instance_validator: true
          optional :another_param_to_validate, instance_validator: true
        end
        get do
          'noop'
        end
      end
    end

    before { stub_const('Grape::Validations::Validators::InstanceValidatorValidator', validator_type) }

    it 'passes validation every time' do
      expect(validator_type).to receive(:new).twice.and_call_original
      get '/', param_to_validate: 'value', another_param_to_validate: 'value'
      expect(last_response.status).to eq 200
    end
  end
end
