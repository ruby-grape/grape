# frozen_string_literal: true

describe Grape::Validations::ParamsScope do
  subject do
    Class.new(Grape::API)
  end

  def app
    subject
  end

  context 'when using custom types' do
    module ParamsScopeSpec
      class CustomType
        attr_reader :value

        def self.parse(value)
          raise if value == 'invalid'

          new(value)
        end

        def initialize(value)
          @value = value
        end
      end
    end

    it 'coerces the parameter via the type\'s parse method' do
      subject.params do
        requires :foo, type: ParamsScopeSpec::CustomType
      end
      subject.get('/types') { params[:foo].value }

      get '/types', foo: 'valid'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('valid')

      get '/types', foo: 'invalid'
      expect(last_response.status).to eq(400)
      expect(last_response.body).to match(/foo is invalid/)
    end
  end

  context 'param renaming' do
    it do
      subject.params do
        requires :foo, as: :bar
        optional :super, as: :hiper
      end
      subject.get('/renaming') { "#{declared(params)['bar']}-#{declared(params)['hiper']}" }
      get '/renaming', foo: 'any', super: 'any2'

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('any-any2')
    end

    it do
      subject.params do
        requires :foo, as: :bar, type: String, coerce_with: ->(c) { c.strip }
      end
      subject.get('/renaming-coerced') { "#{params['bar']}-#{params['foo']}" }
      get '/renaming-coerced', foo: ' there we go '

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('-there we go')
    end

    it do
      subject.params do
        requires :foo, as: :bar, allow_blank: false
      end
      subject.get('/renaming-not-blank') {}
      get '/renaming-not-blank', foo: ''

      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('foo is empty')
    end

    it do
      subject.params do
        requires :foo, as: :bar, allow_blank: false
      end
      subject.get('/renaming-not-blank-with-value') {}
      get '/renaming-not-blank-with-value', foo: 'any'

      expect(last_response.status).to eq(200)
    end

    it do
      subject.params do
        requires :foo, as: :baz, type: Hash do
          requires :bar, as: :qux
        end
      end
      subject.get('/nested-renaming') { declared(params).to_json }
      get '/nested-renaming', foo: { bar: 'any' }

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('{"baz":{"qux":"any"}}')
    end

    it 'renaming can be defined before default' do
      subject.params do
        optional :foo, as: :bar, default: 'before'
      end
      subject.get('/rename-before-default') { declared(params)[:bar] }
      get '/rename-before-default'

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('before')
    end

    it 'renaming can be defined after default' do
      subject.params do
        optional :foo, default: 'after', as: :bar
      end
      subject.get('/rename-after-default') { declared(params)[:bar] }
      get '/rename-after-default'

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('after')
    end
  end

  context 'array without coerce type explicitly given' do
    it 'sets the type based on first element' do
      subject.params do
        requires :periods, type: Array, values: -> { %w[day month] }
      end
      subject.get('/required') { 'required works' }

      get '/required', periods: %w[day month]
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('required works')
    end

    it 'fails to call API without Array type' do
      subject.params do
        requires :periods, type: Array, values: -> { %w[day month] }
      end
      subject.get('/required') { 'required works' }

      get '/required', periods: 'day'
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('periods is invalid')
    end

    it 'raises exception when values are of different type' do
      expect do
        subject.params { requires :numbers, type: Array, values: [1, 'definitely not a number', 3] }
      end.to raise_error Grape::Exceptions::IncompatibleOptionValues
    end

    it 'raises exception when range values have different endpoint types' do
      expect do
        subject.params { requires :numbers, type: Array, values: 0.0..10 }
      end.to raise_error Grape::Exceptions::IncompatibleOptionValues
    end
  end

  context 'coercing values validation with proc' do
    it 'allows the proc to pass validation without checking' do
      subject.params { requires :numbers, type: Integer, values: -> { [0, 1, 2] } }

      subject.post('/required') { 'coercion with proc works' }
      post '/required', numbers: '1'
      expect(last_response.status).to eq(201)
      expect(last_response.body).to eq('coercion with proc works')
    end

    it 'allows the proc to pass validation without checking in value' do
      subject.params { requires :numbers, type: Integer, values: { value: -> { [0, 1, 2] } } }

      subject.post('/required') { 'coercion with proc works' }
      post '/required', numbers: '1'
      expect(last_response.status).to eq(201)
      expect(last_response.body).to eq('coercion with proc works')
    end

    it 'allows the proc to pass validation without checking in except' do
      subject.params { requires :numbers, type: Integer, values: { except: -> { [0, 1, 2] } } }

      subject.post('/required') { 'coercion with proc works' }
      post '/required', numbers: '10'
      expect(last_response.status).to eq(201)
      expect(last_response.body).to eq('coercion with proc works')
    end
  end

  context 'with range values' do
    context "when left range endpoint isn't #kind_of? the type" do
      it 'raises exception' do
        expect do
          subject.params { requires :latitude, type: Integer, values: -90.0..90 }
        end.to raise_error Grape::Exceptions::IncompatibleOptionValues
      end
    end

    context "when right range endpoint isn't #kind_of? the type" do
      it 'raises exception' do
        expect do
          subject.params { requires :latitude, type: Integer, values: -90..90.0 }
        end.to raise_error Grape::Exceptions::IncompatibleOptionValues
      end
    end

    context 'when the default is an array' do
      context 'and is the entire range of allowed values' do
        it 'does not raise an exception' do
          expect do
            subject.params { optional :numbers, type: Array[Integer], values: 0..2, default: 0..2 }
          end.not_to raise_error
        end
      end

      context 'and is a subset of allowed values' do
        it 'does not raise an exception' do
          expect do
            subject.params { optional :numbers, type: Array[Integer], values: [0, 1, 2], default: [1, 0] }
          end.not_to raise_error
        end
      end
    end

    context 'when both range endpoints are #kind_of? the type' do
      it 'accepts values in the range' do
        subject.params do
          requires :letter, type: String, values: 'a'..'z'
        end
        subject.get('/letter') { params[:letter] }

        get '/letter', letter: 'j'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('j')
      end

      it 'rejects values outside the range' do
        subject.params do
          requires :letter, type: String, values: 'a'..'z'
        end
        subject.get('/letter') { params[:letter] }

        get '/letter', letter: 'J'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('letter does not have a valid value')
      end
    end
  end

  context 'parameters in group' do
    it 'errors when no type is provided' do
      expect do
        subject.params do
          group :a do
            requires :b
          end
        end
      end.to raise_error Grape::Exceptions::MissingGroupType

      expect do
        subject.params do
          optional :a do
            requires :b
          end
        end
      end.to raise_error Grape::Exceptions::MissingGroupType
    end

    it 'allows Hash as type' do
      subject.params do
        group :a, type: Hash do
          requires :b
        end
      end
      subject.get('/group') { 'group works' }
      get '/group', a: { b: true }
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('group works')

      subject.params do
        optional :a, type: Hash do
          requires :b
        end
      end
      get '/optional_type_hash'
    end

    it 'allows Array as type' do
      subject.params do
        group :a, type: Array do
          requires :b
        end
      end
      subject.get('/group') { 'group works' }
      get '/group', a: [{ b: true }]
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('group works')

      subject.params do
        optional :a, type: Array do
          requires :b
        end
      end
      get '/optional_type_array'
    end

    it 'handles missing optional Array type' do
      subject.params do
        optional :a, type: Array do
          requires :b
        end
      end
      subject.get('/test') { declared(params).to_json }
      get '/test'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('{"a":[]}')
    end

    it 'errors with an unsupported type' do
      expect do
        subject.params do
          group :a, type: Set do
            requires :b
          end
        end
      end.to raise_error Grape::Exceptions::UnsupportedGroupType

      expect do
        subject.params do
          optional :a, type: Set do
            requires :b
          end
        end
      end.to raise_error Grape::Exceptions::UnsupportedGroupType
    end
  end

  context 'when validations are dependent on a parameter' do
    before do
      subject.params do
        optional :a
        given :a do
          requires :b
        end
      end
      subject.get('/test') { declared(params).to_json }
    end

    it 'applies the validations only if the parameter is present' do
      get '/test'
      expect(last_response.status).to eq(200)

      get '/test', a: true
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('b is missing')

      get '/test', a: true, b: true
      expect(last_response.status).to eq(200)
    end

    it 'applies the validations of multiple parameters' do
      subject.params do
        optional :a, :b
        given :a, :b do
          requires :c
        end
      end
      subject.get('/multiple') { declared(params).to_json }

      get '/multiple'
      expect(last_response.status).to eq(200)

      get '/multiple', a: true
      expect(last_response.status).to eq(200)

      get '/multiple', b: true
      expect(last_response.status).to eq(200)

      get '/multiple', a: true, b: true
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('c is missing')

      get '/multiple', a: true, b: true, c: true
      expect(last_response.status).to eq(200)
    end

    it 'applies only the appropriate validation' do
      subject.params do
        optional :a
        optional :b
        mutually_exclusive :a, :b
        given :a do
          requires :c, type: String
        end
        given :b do
          requires :c, type: Integer
        end
      end
      subject.get('/multiple') { declared(params).to_json }

      get '/multiple'
      expect(last_response.status).to eq(200)

      get '/multiple', a: true, c: 'test'
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body).symbolize_keys).to eq a: 'true', b: nil, c: 'test'

      get '/multiple', b: true, c: '3'
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body).symbolize_keys).to eq a: nil, b: 'true', c: 3

      get '/multiple', a: true
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('c is missing')

      get '/multiple', b: true
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('c is missing')

      get '/multiple', a: true, b: true, c: 'test'
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('a, b are mutually exclusive, c is invalid')
    end

    it 'raises an error if the dependent parameter was never specified' do
      expect do
        subject.params do
          given :c do
          end
        end
      end.to raise_error(Grape::Exceptions::UnknownParameter)
    end

    it 'does not raise an error if the dependent parameter is a Hash' do
      expect do
        subject.params do
          optional :a, type: Hash do
            requires :b
          end
          given :a do
            requires :c
          end
        end
      end.not_to raise_error
    end

    it 'does not raise an error if when using nested given' do
      expect do
        subject.params do
          optional :a, type: Hash do
            requires :b
          end
          given :a do
            requires :c
            given :c do
              requires :d
            end
          end
        end
      end.not_to raise_error
    end

    it 'allows nested dependent parameters' do
      subject.params do
        optional :a
        given a: ->(val) { val == 'a' } do
          optional :b
          given b: ->(val) { val == 'b' } do
            optional :c
            given c: ->(val) { val == 'c' } do
              requires :d
            end
          end
        end
      end
      subject.get('/') { declared(params).to_json }

      get '/'
      expect(last_response.status).to eq 200

      get '/', a: 'a', b: 'b', c: 'c'
      expect(last_response.status).to eq 400
      expect(last_response.body).to eq 'd is missing'

      get '/', a: 'a', b: 'b', c: 'c', d: 'd'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq({ a: 'a', b: 'b', c: 'c', d: 'd' }.to_json)
    end

    it 'allows renaming of dependent parameters' do
      subject.params do
        optional :a
        given :a do
          requires :b, as: :c
        end
      end

      subject.get('/multiple') { declared(params).to_json }

      get '/multiple', a: 'a', b: 'b'

      body = JSON.parse(last_response.body)

      expect(body.keys).to include('c')
      expect(body.keys).not_to include('b')
    end

    it 'allows renaming of dependent on parameter' do
      subject.params do
        optional :a, as: :b
        given a: ->(val) { val == 'x' } do
          requires :c
        end
      end
      subject.get('/') { declared(params) }

      get '/', a: 'x'
      expect(last_response.status).to eq 400
      expect(last_response.body).to eq 'c is missing'

      get '/', a: 'y'
      expect(last_response.status).to eq 200
    end

    it 'does not raise if the dependent parameter is not the renamed one' do
      expect do
        subject.params do
          optional :a, as: :b
          given :a do
            requires :c
          end
        end
      end.not_to raise_error
    end

    it 'raises an error if the dependent parameter is the renamed one' do
      expect do
        subject.params do
          optional :a, as: :b
          given :b do
            requires :c
          end
        end
      end.to raise_error(Grape::Exceptions::UnknownParameter)
    end

    it 'does not validate nested requires when given is false' do
      subject.params do
        requires :a, type: String, allow_blank: false, values: %w[x y z]
        given a: ->(val) { val == 'x' } do
          requires :inner1, type: Hash, allow_blank: false do
            requires :foo, type: Integer, allow_blank: false
          end
        end
        given a: ->(val) { val == 'y' } do
          requires :inner2, type: Hash, allow_blank: false do
            requires :bar, type: Integer, allow_blank: false
            requires :baz, type: Array, allow_blank: false do
              requires :baz_category, type: String, allow_blank: false
            end
          end
        end
        given a: ->(val) { val == 'z' } do
          requires :inner3, type: Array, allow_blank: false do
            requires :bar, type: Integer, allow_blank: false
            requires :baz, type: Array, allow_blank: false do
              requires :baz_category, type: String, allow_blank: false
            end
          end
        end
      end
      subject.get('/varying') { declared(params).to_json }

      get '/varying', a: 'x', inner1: { foo: 1 }
      expect(last_response.status).to eq(200)

      get '/varying', a: 'y', inner2: { bar: 2, baz: [{ baz_category: 'barstools' }] }
      expect(last_response.status).to eq(200)

      get '/varying', a: 'y', inner2: { bar: 2, baz: [{ unrelated: 'yep' }] }
      expect(last_response.status).to eq(400)

      get '/varying', a: 'z', inner3: [{ bar: 3, baz: [{ baz_category: 'barstools' }] }]
      expect(last_response.status).to eq(200)
    end

    it 'detect unmet nested dependency' do
      subject.params do
        requires :a, type: String, allow_blank: false, values: %w[x y z]
        given a: ->(val) { val == 'z' } do
          requires :inner3, type: Array, allow_blank: false do
            requires :bar, type: String, allow_blank: false
            given bar: ->(val) { val == 'b' } do
              requires :baz, type: Array do
                optional :baz_category, type: String
              end
            end
            given bar: ->(val) { val == 'c' } do
              requires :baz, type: Array do
                requires :baz_category, type: String
              end
            end
          end
        end
      end
      subject.get('/nested-dependency') { declared(params).to_json }

      get '/nested-dependency', a: 'z', inner3: [{ bar: 'c', baz: [{ unrelated: 'nope' }] }]
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq 'inner3[0][baz][0][baz_category] is missing'
    end

    it 'includes the parameter within #declared(params)' do
      get '/test', a: true, b: true

      expect(JSON.parse(last_response.body)).to eq('a' => 'true', 'b' => 'true')
    end

    it 'returns a sensible error message within a nested context' do
      subject.params do
        requires :bar, type: Hash do
          optional :a
          given :a do
            requires :b
          end
        end
      end
      subject.get('/nested') { 'worked' }

      get '/nested', bar: { a: true }
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('bar[b] is missing')
    end

    it 'includes the nested parameter within #declared(params)' do
      subject.params do
        requires :bar, type: Hash do
          optional :a
          given :a do
            requires :b
          end
        end
      end
      subject.get('/nested') { declared(params).to_json }

      get '/nested', bar: { a: true, b: 'yes' }
      expect(JSON.parse(last_response.body)).to eq('bar' => { 'a' => 'true', 'b' => 'yes' })
    end

    it 'includes level 2 nested parameters outside the given within #declared(params)' do
      subject.params do
        requires :bar, type: Hash do
          optional :a
          given :a do
            requires :c, type: Hash do
              requires :b
            end
          end
        end
      end
      subject.get('/nested') { declared(params).to_json }

      get '/nested', bar: { a: true, c: { b: 'yes' } }
      expect(JSON.parse(last_response.body)).to eq('bar' => { 'a' => 'true', 'c' => { 'b' => 'yes' } })
    end

    context 'when the dependent parameter is not present #declared(params)' do
      context 'lateral parameter' do
        before do
          [true, false].each do |evaluate_given|
            subject.params do
              optional :a
              given :a do
                optional :b
              end
            end
            subject.get("/evaluate_given_#{evaluate_given}") { declared(params, evaluate_given: evaluate_given).to_json }
          end
        end

        it 'evaluate_given_false' do
          get '/evaluate_given_false', b: 'b'
          expect(JSON.parse(last_response.body)).to eq('a' => nil, 'b' => 'b')
        end

        it 'evaluate_given_true' do
          get '/evaluate_given_true', b: 'b'
          expect(JSON.parse(last_response.body)).to eq('a' => nil)
        end
      end

      context 'lateral hash parameter' do
        before do
          [true, false].each do |evaluate_given|
            subject.params do
              optional :a, values: %w[x y]
              given a: ->(a) { a == 'x' } do
                optional :b, type: Hash do
                  optional :c
                end
                optional :e
              end
              given a: ->(a) { a == 'y' } do
                optional :b, type: Hash do
                  optional :d
                end
                optional :f
              end
            end
            subject.get("/evaluate_given_#{evaluate_given}") { declared(params, evaluate_given: evaluate_given).to_json }
          end
        end

        it 'evaluate_given_false' do
          get '/evaluate_given_false', a: 'x'
          expect(JSON.parse(last_response.body)).to eq('a' => 'x', 'b' => { 'd' => nil }, 'e' => nil, 'f' => nil)

          get '/evaluate_given_false', a: 'y'
          expect(JSON.parse(last_response.body)).to eq('a' => 'y', 'b' => { 'd' => nil }, 'e' => nil, 'f' => nil)
        end

        it 'evaluate_given_true' do
          get '/evaluate_given_true', a: 'x'
          expect(JSON.parse(last_response.body)).to eq('a' => 'x', 'b' => { 'c' => nil }, 'e' => nil)

          get '/evaluate_given_true', a: 'y'
          expect(JSON.parse(last_response.body)).to eq('a' => 'y', 'b' => { 'd' => nil }, 'f' => nil)
        end
      end

      context 'lateral parameter within lateral hash parameter' do
        before do
          [true, false].each do |evaluate_given|
            subject.params do
              optional :a, values: %w[x y]
              given a: ->(a) { a == 'x' } do
                optional :b, type: Hash do
                  optional :c
                  given :c do
                    optional :g
                    optional :e, type: Hash do
                      optional :h
                    end
                  end
                end
              end
              given a: ->(a) { a == 'y' } do
                optional :b, type: Hash do
                  optional :d
                  given :d do
                    optional :f
                    optional :e, type: Hash do
                      optional :i
                    end
                  end
                end
              end
            end
            subject.get("/evaluate_given_#{evaluate_given}") { declared(params, evaluate_given: evaluate_given).to_json }
          end
        end

        it 'evaluate_given_false' do
          get '/evaluate_given_false', a: 'x'
          expect(JSON.parse(last_response.body)).to eq('a' => 'x', 'b' => { 'd' => nil, 'f' => nil, 'e' => { 'i' => nil } })

          get '/evaluate_given_false', a: 'x', b: { c: 'c' }
          expect(JSON.parse(last_response.body)).to eq('a' => 'x', 'b' => { 'd' => nil, 'f' => nil, 'e' => { 'i' => nil } })

          get '/evaluate_given_false', a: 'y'
          expect(JSON.parse(last_response.body)).to eq('a' => 'y', 'b' => { 'd' => nil, 'f' => nil, 'e' => { 'i' => nil } })

          get '/evaluate_given_false', a: 'y', b: { d: 'd' }
          expect(JSON.parse(last_response.body)).to eq('a' => 'y', 'b' => { 'd' => 'd', 'f' => nil, 'e' => { 'i' => nil } })
        end

        it 'evaluate_given_true' do
          get '/evaluate_given_true', a: 'x'
          expect(JSON.parse(last_response.body)).to eq('a' => 'x', 'b' => { 'c' => nil })

          get '/evaluate_given_true', a: 'x', b: { c: 'c' }
          expect(JSON.parse(last_response.body)).to eq('a' => 'x', 'b' => { 'c' => 'c', 'g' => nil, 'e' => { 'h' => nil } })

          get '/evaluate_given_true', a: 'y'
          expect(JSON.parse(last_response.body)).to eq('a' => 'y', 'b' => { 'd' => nil })

          get '/evaluate_given_true', a: 'y', b: { d: 'd' }
          expect(JSON.parse(last_response.body)).to eq('a' => 'y', 'b' => { 'd' => 'd', 'f' => nil, 'e' => { 'i' => nil } })
        end
      end

      context 'lateral parameter within an array param' do
        before do
          [true, false].each do |evaluate_given|
            subject.params do
              optional :array, type: Array do
                optional :a
                given :a do
                  optional :b
                end
              end
            end
            subject.post("/evaluate_given_#{evaluate_given}") do
              declared(params, evaluate_given: evaluate_given).to_json
            end
          end
        end

        it 'evaluate_given_false' do
          post '/evaluate_given_false', { array: [{ b: 'b' }, { a: 'a', b: 'b' }] }.to_json, 'CONTENT_TYPE' => 'application/json'
          expect(JSON.parse(last_response.body)).to eq('array' => [{ 'a' => nil, 'b' => 'b' }, { 'a' => 'a', 'b' => 'b' }])
        end

        it 'evaluate_given_true' do
          post '/evaluate_given_true', { array: [{ b: 'b' }, { a: 'a', b: 'b' }] }.to_json, 'CONTENT_TYPE' => 'application/json'
          expect(JSON.parse(last_response.body)).to eq('array' => [{ 'a' => nil }, { 'a' => 'a', 'b' => 'b' }])
        end
      end

      context 'nested given parameter' do
        before do
          [true, false].each do |evaluate_given|
            subject.params do
              optional :a
              optional :c
              given :a do
                given :c do
                  optional :b
                end
              end
            end
            subject.post("/evaluate_given_#{evaluate_given}") do
              declared(params, evaluate_given: evaluate_given).to_json
            end
          end
        end

        it 'evaluate_given_false' do
          post '/evaluate_given_false', { a: 'a', b: 'b' }.to_json, 'CONTENT_TYPE' => 'application/json'
          expect(JSON.parse(last_response.body)).to eq('a' => 'a', 'b' => 'b', 'c' => nil)

          post '/evaluate_given_false', { c: 'c', b: 'b' }.to_json, 'CONTENT_TYPE' => 'application/json'
          expect(JSON.parse(last_response.body)).to eq('a' => nil, 'b' => 'b', 'c' => 'c')

          post '/evaluate_given_false', { a: 'a', c: 'c', b: 'b' }.to_json, 'CONTENT_TYPE' => 'application/json'
          expect(JSON.parse(last_response.body)).to eq('a' => 'a', 'b' => 'b', 'c' => 'c')
        end

        it 'evaluate_given_true' do
          post '/evaluate_given_true', { a: 'a', b: 'b' }.to_json, 'CONTENT_TYPE' => 'application/json'
          expect(JSON.parse(last_response.body)).to eq('a' => 'a', 'c' => nil)

          post '/evaluate_given_true', { c: 'c', b: 'b' }.to_json, 'CONTENT_TYPE' => 'application/json'
          expect(JSON.parse(last_response.body)).to eq('a' => nil, 'c' => 'c')

          post '/evaluate_given_true', { a: 'a', c: 'c', b: 'b' }.to_json, 'CONTENT_TYPE' => 'application/json'
          expect(JSON.parse(last_response.body)).to eq('a' => 'a', 'b' => 'b', 'c' => 'c')
        end
      end

      context 'nested given parameter within an array param' do
        before do
          [true, false].each do |evaluate_given|
            subject.params do
              optional :array, type: Array do
                optional :a
                optional :c
                given :a do
                  given :c do
                    optional :b
                  end
                end
              end
            end
            subject.post("/evaluate_given_#{evaluate_given}") do
              declared(params, evaluate_given: evaluate_given).to_json
            end
          end
        end

        let :evaluate_given_params do
          {
            array: [
              { a: 'a', b: 'b' },
              { c: 'c', b: 'b' },
              { a: 'a', c: 'c', b: 'b' }
            ]
          }
        end

        it 'evaluate_given_false' do
          post '/evaluate_given_false', evaluate_given_params.to_json, 'CONTENT_TYPE' => 'application/json'
          expect(JSON.parse(last_response.body)).to eq('array' => [{ 'a' => 'a', 'b' => 'b', 'c' => nil }, { 'a' => nil, 'b' => 'b', 'c' => 'c' }, { 'a' => 'a', 'b' => 'b', 'c' => 'c' }])
        end

        it 'evaluate_given_true' do
          post '/evaluate_given_true', evaluate_given_params.to_json, 'CONTENT_TYPE' => 'application/json'
          expect(JSON.parse(last_response.body)).to eq('array' => [{ 'a' => 'a', 'c' => nil }, { 'a' => nil, 'c' => 'c' }, { 'a' => 'a', 'b' => 'b', 'c' => 'c' }])
        end
      end

      context 'nested given parameter within a nested given parameter within an array param' do
        before do
          [true, false].each do |evaluate_given|
            subject.params do
              optional :array, type: Array do
                optional :a
                optional :c
                given :a do
                  given :c do
                    optional :array, type: Array do
                      optional :a
                      optional :c
                      given :a do
                        given :c do
                          optional :b
                        end
                      end
                    end
                  end
                end
              end
            end
            subject.post("/evaluate_given_#{evaluate_given}") do
              declared(params, evaluate_given: evaluate_given).to_json
            end
          end
        end

        let :evaluate_given_params do
          {
            array: [{
              a: 'a',
              c: 'c',
              array: [
                { a: 'a', b: 'b' },
                { c: 'c', b: 'b' },
                { a: 'a', c: 'c', b: 'b' }
              ]
            }]
          }
        end

        it 'evaluate_given_false' do
          expected_response_hash = {
            'array' => [{
              'a' => 'a',
              'c' => 'c',
              'array' => [
                { 'a' => 'a', 'b' => 'b', 'c' => nil },
                { 'a' => nil, 'c' => 'c', 'b' => 'b' },
                { 'a' => 'a', 'c' => 'c', 'b' => 'b' }
              ]
            }]
          }
          post '/evaluate_given_false', evaluate_given_params.to_json, 'CONTENT_TYPE' => 'application/json'
          expect(JSON.parse(last_response.body)).to eq(expected_response_hash)
        end

        it 'evaluate_given_true' do
          expected_response_hash = {
            'array' => [{
              'a' => 'a',
              'c' => 'c',
              'array' => [
                { 'a' => 'a', 'c' => nil },
                { 'a' => nil, 'c' => 'c' },
                { 'a' => 'a', 'b' => 'b', 'c' => 'c' }
              ]
            }]
          }
          post '/evaluate_given_true', evaluate_given_params.to_json, 'CONTENT_TYPE' => 'application/json'
          expect(JSON.parse(last_response.body)).to eq(expected_response_hash)
        end
      end
    end
  end

  context 'default value in given block' do
    before do
      subject.params do
        optional :a, values: %w[a b]
        given a: ->(val) { val == 'a' } do
          optional :b, default: 'default'
        end
      end
      subject.get('/') { params.to_json }
    end

    context 'when dependency meets' do
      it 'sets default value for dependent parameter' do
        get '/', a: 'a'
        expect(last_response.body).to eq({ a: 'a', b: 'default' }.to_json)
      end
    end

    context 'when dependency does not meet' do
      it 'does not set default value for dependent parameter' do
        get '/', a: 'b'
        expect(last_response.body).to eq({ a: 'b' }.to_json)
      end
    end
  end

  context 'when validations are dependent on a parameter within an array param' do
    before do
      subject.params do
        requires :foos, type: Array do
          optional :foo
          given :foo do
            requires :bar
          end
        end
      end
      subject.get('/test') { 'ok' }
    end

    it 'passes none Hash params' do
      get '/test', foos: ['']
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('ok')
    end
  end

  context 'when validations are dependent on a parameter within an array param within #declared(params).to_json' do
    before do
      subject.params do
        requires :foos, type: Array do
          optional :foo_type, :baz_type
          given :foo_type do
            requires :bar
          end
        end
      end
      subject.post('/test') { declared(params).to_json }
    end

    it 'applies the constraint within each value' do
      post '/test',
           { foos: [{ foo_type: 'a' }, { baz_type: 'c' }] }.to_json,
           'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('foos[0][bar] is missing')
    end
  end

  context 'when validations are dependent on a parameter with specific value' do
    # build test cases from all combinations of declarations and options
    a_decls = %i[optional requires]
    a_options = [{}, { values: %w[x y z] }]
    b_options = [{}, { type: String }, { allow_blank: false }, { type: String, allow_blank: false }]
    combinations = a_decls.product(a_options, b_options)
    combinations.each_with_index do |combination, i|
      a_decl, a_opts, b_opts = combination

      context "(case #{i})" do
        before do
          # puts "a_decl: #{a_decl}, a_opts: #{a_opts}, b_opts: #{b_opts}"
          subject.params do
            send a_decl, :a, **a_opts
            given(a: ->(val) { val == 'x' }) { requires :b, **b_opts }
            given(a: ->(val) { val == 'y' }) { requires :c, **b_opts }
          end
          subject.get('/test') { declared(params).to_json }
        end

        if a_decl == :optional
          it 'skips validation when base param is missing' do
            get '/test'
            expect(last_response.status).to eq(200)
          end
        end

        it 'skips validation when base param does not have a specified value' do
          get '/test', a: 'z'
          expect(last_response.status).to eq(200)

          get '/test', a: 'z', b: ''
          expect(last_response.status).to eq(200)
        end

        it 'applies the validation when base param has the specific value' do
          get '/test', a: 'x'
          expect(last_response.status).to eq(400)
          expect(last_response.body).to include('b is missing')

          get '/test', a: 'x', b: true
          expect(last_response.status).to eq(200)

          get '/test', a: 'x', b: true, c: ''
          expect(last_response.status).to eq(200)
        end

        it 'includes the parameter within #declared(params)' do
          get '/test', a: 'x', b: true
          expect(JSON.parse(last_response.body)).to eq('a' => 'x', 'b' => 'true', 'c' => nil)
        end
      end
    end
  end

  it 'raises an error if the dependent parameter was never specified' do
    expect do
      subject.params do
        given :c do
        end
      end
    end.to raise_error(Grape::Exceptions::UnknownParameter)
  end

  it 'returns a sensible error message within a nested context' do
    subject.params do
      requires :bar, type: Hash do
        optional :a
        given a: ->(val) { val == 'x' } do
          requires :b
        end
      end
    end
    subject.get('/nested') { 'worked' }

    get '/nested', bar: { a: 'x' }
    expect(last_response.status).to eq(400)
    expect(last_response.body).to eq('bar[b] is missing')
  end

  it 'includes the nested parameter within #declared(params)' do
    subject.params do
      requires :bar, type: Hash do
        optional :a
        given a: ->(val) { val == 'x' } do
          requires :b
        end
      end
    end
    subject.get('/nested') { declared(params).to_json }

    get '/nested', bar: { a: 'x', b: 'yes' }
    expect(JSON.parse(last_response.body)).to eq('bar' => { 'a' => 'x', 'b' => 'yes' })
  end

  it 'includes level 2 nested parameters outside the given within #declared(params)' do
    subject.params do
      requires :bar, type: Hash do
        optional :a
        given a: ->(val) { val == 'x' } do
          requires :c, type: Hash do
            requires :b
          end
        end
      end
    end
    subject.get('/nested') { declared(params).to_json }

    get '/nested', bar: { a: 'x', c: { b: 'yes' } }
    expect(JSON.parse(last_response.body)).to eq('bar' => { 'a' => 'x', 'c' => { 'b' => 'yes' } })
  end

  it 'includes deeply nested parameters within #declared(params)' do
    subject.params do
      requires :arr1, type: Array do
        requires :hash1, type: Hash do
          requires :arr2, type: Array do
            requires :hash2, type: Hash do
              requires :something, type: String
            end
          end
        end
      end
    end
    subject.get('/nested_deep') { declared(params).to_json }

    get '/nested_deep', arr1: [{ hash1: { arr2: [{ hash2: { something: 'value' } }] } }]
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq('arr1' => [{ 'hash1' => { 'arr2' => [{ 'hash2' => { 'something' => 'value' } }] } }])
  end

  context 'failing fast' do
    context 'when fail_fast is not defined' do
      it 'does not stop validation' do
        subject.params do
          requires :one
          requires :two
          requires :three
        end
        subject.get('/fail-fast') { declared(params).to_json }

        get '/fail-fast'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('one is missing, two is missing, three is missing')
      end
    end

    context 'when fail_fast is defined it stops the validation' do
      it 'of other params' do
        subject.params do
          requires :one, fail_fast: true
          requires :two
        end
        subject.get('/fail-fast') { declared(params).to_json }

        get '/fail-fast'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('one is missing')
      end

      it 'for a single param' do
        subject.params do
          requires :one, allow_blank: false, regexp: /[0-9]+/, fail_fast: true
        end
        subject.get('/fail-fast') { declared(params).to_json }

        get '/fail-fast', one: ''
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('one is empty')
      end
    end
  end

  context 'when params have group attributes' do
    context 'with validations' do
      before do
        subject.params do
          with(allow_blank: false) do
            requires :id
            optional :name
            optional :address, allow_blank: true
          end
        end
        subject.get('test')
      end

      context 'when data is invalid' do
        before do
          get 'test', id: '', name: ''
        end

        it 'returns a validation error' do
          expect(last_response.status).to eq(400)
        end

        it 'applies group validations for every parameter' do
          expect(last_response.body).to eq('id is empty, name is empty')
        end
      end

      context 'when parameter has the same validator as a group' do
        before do
          get 'test', id: 'id', address: ''
        end

        it 'returns a successful response' do
          expect(last_response.status).to eq(200)
        end

        it 'prioritizes parameter validation over group validation' do
          expect(last_response.body).not_to include('address is empty')
        end
      end
    end

    context 'with types' do
      before do
        subject.params do
          with(type: Date) do
            requires :created_at
          end
        end
        subject.get('test') { params[:created_at] }
      end

      context 'when invalid date provided' do
        before do
          get 'test', created_at: 'not_a_date'
        end

        it 'responds with HTTP error' do
          expect(last_response.status).to eq(400)
        end

        it 'returns a validation error' do
          expect(last_response.body).to eq('created_at is invalid')
        end
      end

      context 'when created_at receives a valid date' do
        before do
          get 'test', created_at: '2016-01-01'
        end

        it 'returns a successful response' do
          expect(last_response.status).to eq(200)
        end

        it 'returns a date' do
          expect(last_response.body).to eq('2016-01-01')
        end
      end
    end

    context 'with several group attributes' do
      before do
        subject.params do
          with(values: [1]) do
            requires :id, type: Integer
          end

          with(allow_blank: false) do
            optional :address, type: String
          end

          requires :name
        end
        subject.get('test')
      end

      context 'when data is invalid' do
        before do
          get 'test', id: 2, address: ''
        end

        it 'responds with HTTP error' do
          expect(last_response.status).to eq(400)
        end

        it 'returns a validation error' do
          expect(last_response.body).to eq('id does not have a valid value, address is empty, name is missing')
        end
      end

      context 'when correct data is provided' do
        before do
          get 'test', id: 1, address: 'Some street', name: 'John'
        end

        it 'returns a successful response' do
          expect(last_response.status).to eq(200)
        end
      end
    end

    context 'with nested groups' do
      before do
        subject.params do
          with(type: Integer) do
            requires :id

            with(type: Date) do
              requires :created_at
              optional :updated_at
            end
          end
        end
        subject.get('test')
      end

      context 'when data is invalid' do
        before do
          get 'test', id: 'wrong', created_at: 'not_a_date', updated_at: '2016-01-01'
        end

        it 'responds with HTTP error' do
          expect(last_response.status).to eq(400)
        end

        it 'returns a validation error' do
          expect(last_response.body).to eq('id is invalid, created_at is invalid')
        end
      end

      context 'when correct data is provided' do
        before do
          get 'test', id: 1, created_at: '2016-01-01'
        end

        it 'returns a successful response' do
          expect(last_response.status).to eq(200)
        end
      end
    end
  end

  context 'with exactly_one_of validation for optional parameters within an Hash param' do
    before do
      subject.params do
        optional :memo, type: Hash do
          optional :text, type: String
          optional :custom_body, type: Hash, coerce_with: JSON
          exactly_one_of :text, :custom_body
        end
      end
      subject.get('test')
    end

    context 'when correct data is provided' do
      it 'returns a successful response' do
        get 'test', memo: {}
        expect(last_response.status).to eq(200)

        get 'test', memo: { text: 'HOGEHOGE' }
        expect(last_response.status).to eq(200)

        get 'test', memo: { custom_body: '{ "xxx": "yyy" }' }
        expect(last_response.status).to eq(200)
      end
    end

    context 'when invalid data is provided' do
      it 'returns a failure response' do
        get 'test', memo: { text: 'HOGEHOGE', custom_body: '{ "xxx": "yyy" }' }
        expect(last_response.status).to eq(400)

        get 'test', memo: '{ "custom_body": "HOGE" }'
        expect(last_response.status).to eq(400)
      end
    end
  end
end
