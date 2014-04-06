# encoding: utf-8
require 'spec_helper'

describe Grape::Validations::CoerceValidator do
  subject do
    Class.new(Grape::API)
  end

  def app
    subject
  end

  describe 'coerce' do

    context "i18n" do

      after :each do
        I18n.locale = :en
      end

      it "i18n error on malformed input" do
        I18n.load_path << File.expand_path('../zh-CN.yml', __FILE__)
        I18n.reload!
        I18n.locale = 'zh-CN'.to_sym
        subject.params do
          requires :age, type: Integer
        end
        subject.get '/single' do
          'int works'
        end

        get '/single', age: '43a'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('年龄格式不正确')
      end

      it 'gives an english fallback error when default locale message is blank' do
        I18n.locale = 'pt-BR'.to_sym
        subject.params do
          requires :age, type: Integer
        end
        subject.get '/single' do
          'int works'
        end

        get '/single', age: '43a'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('age is invalid')
      end

    end

    it 'error on malformed input' do
      subject.params do
        requires :int, type: Integer
      end
      subject.get '/single' do
        'int works'
      end

      get '/single', int: '43a'
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('int is invalid')

      get '/single', int: '43'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('int works')
    end

    it 'error on malformed input (Array)' do
      subject.params do
        requires :ids, type: Array[Integer]
      end
      subject.get '/array' do
        'array int works'
      end

      get 'array', ids: ['1', '2', 'az']
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('ids is invalid')

      get 'array', ids: ['1', '2', '890']
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('array int works')
    end

    context 'complex objects' do
      module CoerceValidatorSpec
        class User
          include Virtus.model
          attribute :id, Integer
          attribute :name, String
        end
      end

      it 'error on malformed input for complex objects' do
        subject.params do
          requires :user, type: CoerceValidatorSpec::User
        end
        subject.get '/user' do
          'complex works'
        end

        get '/user', user: "32"
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('user is invalid')

        get '/user', user: { id: 32, name: 'Bob' }
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('complex works')
      end
    end

    context 'coerces' do
      it 'Integer' do
        subject.params do
          requires :int, coerce: Integer
        end
        subject.get '/int' do
          params[:int].class
        end

        get '/int', int: "45"
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('Fixnum')
      end

      it 'Array of Integers' do
        subject.params do
          requires :arry, coerce: Array[Integer]
        end
        subject.get '/array' do
          params[:arry][0].class
        end

        get '/array', arry: ['1', '2', '3']
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('Fixnum')
      end

      it 'Array of Bools' do
        subject.params do
          requires :arry, coerce: Array[Virtus::Attribute::Boolean]
        end
        subject.get '/array' do
          params[:arry][0].class
        end

        get 'array', arry: [1, 0]
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('TrueClass')
      end

      it 'Bool' do
        subject.params do
          requires :bool, coerce: Virtus::Attribute::Boolean
        end
        subject.get '/bool' do
          params[:bool].class
        end

        get '/bool', bool: 1
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('TrueClass')

        get '/bool', bool: 0
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('FalseClass')

        get '/bool', bool: 'false'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('FalseClass')

        get '/bool', bool: 'true'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('TrueClass')
      end

      it 'file' do
        subject.params do
          requires :file, coerce: Rack::Multipart::UploadedFile
        end
        subject.post '/upload' do
          params[:file].filename
        end

        post '/upload', file: Rack::Test::UploadedFile.new(__FILE__)
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq(File.basename(__FILE__).to_s)
      end

      it 'Nests integers' do
        subject.params do
          requires :integers, type: Hash do
            requires :int, coerce: Integer
          end
        end
        subject.get '/int' do
          params[:integers][:int].class
        end

        get '/int', integers: { int: "45" }
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('Fixnum')
      end
    end
  end
end
