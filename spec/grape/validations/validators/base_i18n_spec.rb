# frozen_string_literal: true

describe Grape::Validations::Validators::Base do
  describe 'i18n' do
    subject { Class.new(Grape::API) }

    let(:app) { subject }

    let(:custom_i18n_validator) do
      Class.new(Grape::Validations::Validators::Base) do
        def initialize(attrs, options, required, scope, opts)
          super
          @exception_message = message(:custom_i18n_test)
        end

        def validate_param!(attr_name, params)
          return if hash_like?(params) && params[attr_name] == 'accept'

          raise Grape::Exceptions::Validation.new(
            params: @scope.full_name(attr_name),
            message: @exception_message
          )
        end
      end
    end

    before do
      I18n.available_locales = %i[en zh-CN]
      I18n.backend.store_translations(:en, grape: { errors: { messages: { custom_i18n_test: 'custom validation failed (en)' } } })
      I18n.backend.store_translations(:'zh-CN', grape: { errors: { messages: { custom_i18n_test: '自定义校验失败 (zh-CN)' } } })
      stub_const('CustomI18nValidator', custom_i18n_validator)
      Grape::Validations.register(CustomI18nValidator)
    end

    after do
      Grape::Validations.deregister('custom_i18n')
      I18n.available_locales = %i[en]
      I18n.reload!
    end

    it 'uses the request-time locale regardless of the locale active at definition time' do
      # Define the API while zh-CN is the active locale
      I18n.with_locale(:'zh-CN') do
        subject.params do
          requires :token, custom_i18n: true
        end
        subject.post do
        end
      end
      # Switch to English before making the request
      I18n.with_locale(:en) do
        post '/', token: 'reject'
      end

      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('token custom validation failed (en)')
    end

    it 'uses zh-CN message when request is made with zh-CN locale' do
      I18n.with_locale(:en) do
        subject.params do
          requires :token, custom_i18n: true
        end
        subject.post do
        end
      end

      I18n.with_locale(:'zh-CN') do
        post '/', token: 'reject'
      end

      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('token 自定义校验失败 (zh-CN)')
    end
  end
end
