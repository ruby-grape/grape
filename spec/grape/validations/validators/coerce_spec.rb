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
    module CoerceValidatorSpec
      class User
        include Virtus.model
        attribute :id, Integer
        attribute :name, String
      end
    end

    context 'i18n' do
      after :each do
        I18n.locale = :en
      end

      it 'i18n error on malformed input' do
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

      get 'array', ids: %w(1 2 az)
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('ids is invalid')

      get 'array', ids: %w(1 2 890)
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('array int works')
    end

    context 'complex objects' do
      it 'error on malformed input for complex objects' do
        subject.params do
          requires :user, type: CoerceValidatorSpec::User
        end
        subject.get '/user' do
          'complex works'
        end

        get '/user', user: '32'
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

        get '/int', int: '45'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('Fixnum')
      end

      context 'Array' do
        it 'Array of Integers' do
          subject.params do
            requires :arry, coerce: Array[Integer]
          end
          subject.get '/array' do
            params[:arry][0].class
          end

          get '/array', arry: %w(1 2 3)
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

        it 'Array of Complex' do
          subject.params do
            requires :arry, coerce: Array[CoerceValidatorSpec::User]
          end
          subject.get '/array' do
            params[:arry].size
          end

          get 'array', arry: [31]
          expect(last_response.status).to eq(400)
          expect(last_response.body).to eq('arry is invalid')

          get 'array', arry: { id: 31, name: 'Alice' }
          expect(last_response.status).to eq(400)
          expect(last_response.body).to eq('arry is invalid')

          get 'array', arry: [{ id: 31, name: 'Alice' }]
          expect(last_response.status).to eq(200)
          expect(last_response.body).to eq('1')
        end
      end

      context 'Set' do
        it 'Set of Integers' do
          subject.params do
            requires :set, coerce: Set[Integer]
          end
          subject.get '/set' do
            params[:set].first.class
          end

          get '/set', set: Set.new([1, 2, 3, 4]).to_a
          expect(last_response.status).to eq(200)
          expect(last_response.body).to eq('Fixnum')
        end

        it 'Set of Bools' do
          subject.params do
            requires :set, coerce: Set[Virtus::Attribute::Boolean]
          end
          subject.get '/set' do
            params[:set].first.class
          end

          get '/set', set: Set.new([1, 0]).to_a
          expect(last_response.status).to eq(200)
          expect(last_response.body).to eq('TrueClass')
        end
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

      it 'Rack::Multipart::UploadedFile' do
        subject.params do
          requires :file, type: Rack::Multipart::UploadedFile
        end
        subject.post '/upload' do
          params[:file].filename
        end

        post '/upload', file: Rack::Test::UploadedFile.new(__FILE__)
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq(File.basename(__FILE__).to_s)

        post '/upload', file: 'not a file'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('file is invalid')
      end

      it 'File' do
        subject.params do
          requires :file, coerce: File
        end
        subject.post '/upload' do
          params[:file].filename
        end

        post '/upload', file: Rack::Test::UploadedFile.new(__FILE__)
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq(File.basename(__FILE__).to_s)

        post '/upload', file: 'not a file'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('file is invalid')
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

        get '/int', integers: { int: '45' }
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('Fixnum')
      end
    end

    context 'using coerce_with' do
      it 'uses parse where available' do
        subject.params do
          requires :ints, type: Array, coerce_with: JSON do
            requires :i, type: Integer
            requires :j
          end
        end
        subject.get '/ints' do
          ints = params[:ints].first
          'coercion works' if ints[:i] == 1 && ints[:j] == '2'
        end

        get '/ints', ints: [{ i: 1, j: '2' }]
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('ints is invalid')

        get '/ints', ints: '{"i":1,"j":"2"}'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('ints[i] is missing, ints[i] is invalid, ints[j] is missing')

        get '/ints', ints: '[{"i":"1","j":"2"}]'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('coercion works')
      end

      it 'accepts any callable' do
        subject.params do
          requires :ints, type: Hash, coerce_with: JSON.method(:parse) do
            requires :int, type: Integer, coerce_with: ->(val) { val == 'three' ? 3 : val }
          end
        end
        subject.get '/ints' do
          params[:ints][:int]
        end

        get '/ints', ints: '{"int":"3"}'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('ints[int] is invalid')

        get '/ints', ints: '{"int":"three"}'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('3')

        get '/ints', ints: '{"int":3}'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('3')
      end

      it 'must be supplied with :type or :coerce' do
        expect do
          subject.params do
            requires :ints, coerce_with: JSON
          end
        end.to raise_error(ArgumentError)
      end
    end

    context 'first-class JSON' do
      it 'parses objects and arrays' do
        subject.params do
          requires :splines, type: JSON do
            requires :x, type: Integer, values: [1, 2, 3]
            optional :ints, type: Array[Integer]
            optional :obj, type: Hash do
              optional :y
            end
          end
        end
        subject.get '/' do
          if params[:splines].is_a? Hash
            params[:splines][:obj][:y]
          else
            'arrays work' if params[:splines].any? { |s| s.key? :obj }
          end
        end

        get '/', splines: '{"x":1,"ints":[1,2,3],"obj":{"y":"woof"}}'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('woof')

        get '/', splines: '[{"x":2,"ints":[]},{"x":3,"ints":[4],"obj":{"y":"quack"}}]'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('arrays work')

        get '/', splines: '{"x":4,"ints":[2]}'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('splines[x] does not have a valid value')

        get '/', splines: '[{"x":1,"ints":[]},{"x":4,"ints":[]}]'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('splines[x] does not have a valid value')
      end

      it 'accepts Array[JSON] shorthand' do
        subject.params do
          requires :splines, type: Array[JSON] do
            requires :x, type: Integer, values: [1, 2, 3]
            requires :y
          end
        end
        subject.get '/' do
          params[:splines].first[:y].class.to_s
          spline = params[:splines].first
          "#{spline[:x].class}.#{spline[:y].class}"
        end

        get '/', splines: '{"x":"1","y":"woof"}'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('Fixnum.String')

        get '/', splines: '[{"x":1,"y":2},{"x":1,"y":"quack"}]'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('Fixnum.Fixnum')

        get '/', splines: '{"x":"4","y":"woof"}'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('splines[x] does not have a valid value')

        get '/', splines: '[{"x":"4","y":"woof"}]'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('splines[x] does not have a valid value')
      end

      it "doesn't make sense using coerce_with" do
        expect do
          subject.params do
            requires :bad, type: JSON, coerce_with: JSON do
              requires :x
            end
          end
        end.to raise_error(ArgumentError)

        expect do
          subject.params do
            requires :bad, type: Array[JSON], coerce_with: JSON do
              requires :x
            end
          end
        end.to raise_error(ArgumentError)
      end
    end

    context 'converter' do
      it 'does not build Virtus::Attribute multiple times' do
        subject.params do
          requires :something, type: Array[String]
        end
        subject.get do
        end

        expect(Virtus::Attribute).to receive(:build).at_most(2).times.and_call_original
        10.times { get '/' }
      end
    end
  end
end
