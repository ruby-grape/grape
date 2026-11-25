# frozen_string_literal: true

# Declares every validator Grape ships, and a custom one, in every kind of
# scope a param can live in, both required and optional, then sends each a
# valid value, an invalid one, nothing, null, values of unexpected types and a
# scope of the wrong type. A validator a request reaches answers with its own
# message, so each one is seen to run, and none of them may answer 500. The
# last example fails when a validator is added without an entry here.
describe Grape::Validations::Validators do
  # +declare+ declares what +inner+ does in this scope, +nest+ puts the
  # params of the scope where a request sends them, +read+ finds one back in
  # the params the endpoint answers, and +wrong_container+ sends the scope a
  # value of the wrong type.
  presences = %i[requires optional].freeze
  unexpected_values = [nil, { 'unexpected' => [1] }, [1, 'x'], 1.5, true].freeze
  group_subsets = [[], %i[a], %i[b], %i[a b]].freeze

  matrix_scope = Struct.new(:name, :declare, :nest, :read, :full_name, :wrong_container, keyword_init: true)

  scopes = [
    matrix_scope.new(
      name: 'the root',
      declare: ->(scope, inner) { inner.call(scope) },
      nest: ->(params) { params },
      read: ->(body) { body },
      full_name: ->(name) { name }
    ),
    matrix_scope.new(
      name: 'a required Hash',
      declare: ->(scope, inner) { scope.requires(:outer, type: Hash) { inner.call(self) } },
      nest: ->(params) { { outer: params } },
      read: ->(body) { body['outer'] },
      full_name: ->(name) { "outer[#{name}]" },
      wrong_container: { outer: 'x' }
    ),
    matrix_scope.new(
      name: 'an optional Hash',
      declare: ->(scope, inner) { scope.optional(:outer, type: Hash) { inner.call(self) } },
      nest: ->(params) { { outer: params } },
      read: ->(body) { body['outer'] },
      full_name: ->(name) { "outer[#{name}]" },
      wrong_container: { outer: 'x' }
    ),
    matrix_scope.new(
      name: 'a required Array',
      declare: ->(scope, inner) { scope.requires(:items, type: Array) { inner.call(self) } },
      nest: ->(params) { { items: [params] } },
      read: ->(body) { body['items'][0] },
      full_name: ->(name) { "items[0][#{name}]" },
      wrong_container: { items: ['x'] }
    ),
    matrix_scope.new(
      name: 'an optional Array',
      declare: ->(scope, inner) { scope.optional(:items, type: Array) { inner.call(self) } },
      nest: ->(params) { { items: [params] } },
      read: ->(body) { body['items'][0] },
      full_name: ->(name) { "items[0][#{name}]" },
      wrong_container: { items: ['x'] }
    ),
    matrix_scope.new(
      name: 'an Array in a Hash',
      declare: lambda { |scope, inner|
        scope.requires(:outer, type: Hash) { requires(:items, type: Array) { inner.call(self) } }
      },
      nest: ->(params) { { outer: { items: [params] } } },
      read: ->(body) { body['outer']['items'][0] },
      full_name: ->(name) { "outer[items][0][#{name}]" },
      wrong_container: { outer: { items: 'x' } }
    ),
    matrix_scope.new(
      name: 'a given',
      declare: lambda { |scope, inner|
        scope.optional :flag, type: Grape::API::Boolean
        scope.given(:flag) { inner.call(self) }
      },
      nest: ->(params) { params.merge(flag: true) },
      read: ->(body) { body },
      full_name: ->(name) { name }
    )
  ]

  # A validator declared on +param+, which is always sent next to +other+, so
  # that an optional scope is never passed over for being empty. +invalid+
  # answers +message+ on the param, or on the element of it +error_suffix+
  # names. +sent+ is the key and value the endpoint reads back for a valid
  # value, and +defaulted+ those it reads back for an optional param left
  # out; a required one left out is missing, default or not.
  matrix_entry = Struct.new(:validator, :options, :block, :valid, :invalid, :message, :error_suffix, :sent, :defaulted, keyword_init: true)

  entries = [
    matrix_entry.new(validator: 'presence', options: {}, valid: 'x'),
    matrix_entry.new(validator: 'coerce', options: { type: Integer }, valid: '1', invalid: 'x', message: 'is invalid', sent: ['param', 1]),
    matrix_entry.new(validator: 'values', options: { type: Integer, values: [1, 2] }, valid: 1, invalid: 3, message: 'does not have a valid value'),
    matrix_entry.new(validator: 'except_values', options: { type: Integer, except_values: [3] }, valid: 1, invalid: 3, message: 'has a value not allowed'),
    matrix_entry.new(validator: 'regexp', options: { regexp: /\A[a-z]+\z/ }, valid: 'abc', invalid: 'ABC', message: 'is invalid'),
    matrix_entry.new(validator: 'allow_blank', options: { allow_blank: false }, valid: 'x', invalid: '', message: 'is empty'),
    matrix_entry.new(
      validator: 'length', options: { type: String, length: { max: 2 } }, valid: 'ab', invalid: 'abc',
      message: 'is expected to have length less than or equal to 2'
    ),
    matrix_entry.new(validator: 'same_as', options: { same_as: :other }, valid: 'o', invalid: 'x', message: 'is not the same as other'),
    matrix_entry.new(
      validator: 'oneof', options: { type: Hash, oneof: [proc { requires :a, type: Integer }] }, valid: { a: '1' }, invalid: { b: 1 },
      message: 'does not match any of the allowed schemas', sent: ['param', { 'a' => 1 }]
    ),
    matrix_entry.new(
      validator: 'hash_elements', options: { type: Array }, block: proc { optional :a }, valid: [{ a: 1 }], invalid: ['x'],
      message: 'is invalid', error_suffix: '[0]'
    ),
    matrix_entry.new(validator: 'default', options: { type: Integer, default: 5 }, valid: 1, sent: ['param', 1], defaulted: ['param', 5]),
    matrix_entry.new(validator: 'as', options: { as: :renamed }, valid: 'x', sent: %w[renamed x]),
    matrix_entry.new(validator: 'matrix_alpha_numeric', options: { matrix_alpha_numeric: true }, valid: 'ab1', invalid: '!', message: 'must be alphanumeric')
  ]

  # Validators of +a+ and +b+ together, which answer +errors+ for the ones
  # sent, and accept any other combination.
  matrix_group = Struct.new(:validator, :errors, keyword_init: true)

  groups = [
    matrix_group.new(validator: 'mutually_exclusive', errors: { %i[a b] => 'are mutually exclusive' }),
    matrix_group.new(
      validator: 'exactly_one_of',
      errors: { [] => 'are missing, exactly one parameter must be provided', %i[a b] => 'are mutually exclusive' }
    ),
    matrix_group.new(validator: 'at_least_one_of', errors: { [] => 'are missing, at least one parameter must be provided' }),
    matrix_group.new(validator: 'all_or_none_of', errors: { %i[a] => 'provide all or none of parameters', %i[b] => 'provide all or none of parameters' })
  ]

  # Reads the value without asking whether it is there, as the README's
  # example does, which raised on a required param left out (#1693).
  let(:custom_validator) do
    Class.new(Grape::Validations::Validators::Base) do
      def validate_param!(attr_name, params)
        return if params[attr_name].to_s.match?(/\A[[:alnum:]]+\z/)

        raise Grape::Exceptions::Validation.new(params: [scope.full_name(attr_name)], message: 'must be alphanumeric')
      end
    end
  end

  before do
    stub_const('MatrixAlphaNumericValidator', custom_validator)
    Grape::Validations.register(custom_validator)
  end

  after { Grape::Validations.deregister(:matrix_alpha_numeric) }

  def build_app(scope, &inner)
    Class.new(Grape::API) do
      format :json
      params { scope.declare.call(self, inner) }
      post('/') { declared(params) }
    end
  end

  def send_params(body)
    post '/', body.to_json, 'CONTENT_TYPE' => 'application/json'
  end

  def send_group(scope, given)
    send_params(scope.nest.call(given.to_h { |name| [name, 'x'] }.merge(other: 'o')))
  end

  def error
    JSON.parse(last_response.body)['error']
  end

  def expect_handled
    expect(last_response.status).to eq(201).or(eq(400)), last_response.body
    expect(repeated_errors).to be_empty if last_response.status == 400
  end

  def repeated_errors
    error.split(', ').tally.select { |_, count| count > 1 }.keys
  end

  scopes.each do |scope|
    context "in #{scope.name}" do
      entries.each do |entry|
        presences.each do |presence|
          context "#{presence} :param, #{entry.validator}" do
            let(:app) do
              build_app(scope) do |s|
                s.optional :other
                s.public_send(presence, :param, **entry.options, &entry.block)
              end
            end

            let(:full_name) { scope.full_name.call('param') }

            define_method(:send_param) do |*value|
              params = { other: 'o' }
              params[:param] = value.first unless value.empty?
              send_params(scope.nest.call(params))
            end

            define_method(:read_back) do |key|
              scope.read.call(JSON.parse(last_response.body))[key]
            end

            it 'accepts a valid value' do
              send_param(entry.valid)
              expect(last_response.status).to eq(201), last_response.body
              expect(read_back(entry.sent.first)).to eq(entry.sent.last) if entry.sent
            end

            if entry.invalid
              it "answers #{entry.message.inspect} for an invalid value" do
                send_param(entry.invalid)
                expect(last_response.status).to eq(400)
                expect(error).to eq("#{full_name}#{entry.error_suffix} #{entry.message}")
              end
            end

            if presence == :requires
              it 'answers is missing alone for a param left out' do
                send_param
                expect(last_response.status).to eq(400)
                expect(error).to eq("#{full_name} is missing")
              end
            else
              it 'accepts a param left out' do
                send_param
                expect(last_response.status).to eq(201), last_response.body
                expect(read_back(entry.defaulted.first)).to eq(entry.defaulted.last) if entry.defaulted
              end
            end

            unexpected_values.each do |unexpected|
              it "does not fail on #{unexpected.inspect}" do
                send_param(unexpected)
                expect_handled
              end
            end

            if scope.wrong_container
              it 'does not fail on a scope of the wrong type' do
                send_params(scope.wrong_container)
                expect_handled
              end
            end
          end
        end
      end

      groups.each do |group|
        context group.validator do
          let(:app) do
            build_app(scope) do |s|
              s.optional :other
              s.optional :a
              s.optional :b
              s.public_send(group.validator, :a, :b)
            end
          end

          group_subsets.each do |given|
            if group.errors.key?(given)
              it "answers #{group.errors[given].inspect} for #{given.inspect}" do
                send_group(scope, given)
                expect(last_response.status).to eq(400)
                expect(error).to eq("#{scope.full_name.call('a')}, #{scope.full_name.call('b')} #{group.errors[given]}")
              end
            else
              it "accepts #{given.inspect}" do
                send_group(scope, given)
                expect(last_response.status).to eq(201), last_response.body
              end
            end
          end
        end
      end
    end
  end

  context 'with every validator Grape ships' do
    define_method(:covered) { entries.map(&:validator) + groups.map(&:validator) }

    let(:shipped) do
      described_class.constants.filter_map do |name|
        klass = described_class.const_get(name)
        next unless klass.is_a?(Class) && klass < described_class::Base
        next if klass == described_class::MultipleParamsBase

        Grape::Validations.build_short_name(klass)
      end
    end

    it 'has an entry for each' do
      expect(covered).to include(*shipped)
    end
  end
end
