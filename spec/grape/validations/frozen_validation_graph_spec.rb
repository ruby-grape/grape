# frozen_string_literal: true

# Layer-1 thread-safety invariant: the validation object graph shared across
# requests is immutable. Validators, their iterators, params scopes and
# coercers all freeze at construction (see Grape::Util::FreezeOnNew), so a
# request-time ivar write raises FrozenError deterministically instead of
# being a latent data race.
#
# This spec enforces the contract structurally: it walks every object
# reachable from the compiled routes' validator lists and asserts that each
# instance of a contract class is frozen — catching classes that never
# adopted the freeze contract, not just regressions in those that did.
RSpec.describe Grape::Validations do
  describe 'frozen shared validation graph' do
    let(:custom_type) do
      Class.new do
        def self.parse(value)
          value.to_s
        end
      end
    end

    # One API touching every validator and coercer shape, so the walk sweeps
    # the whole taxonomy: primitive/array/set/nested/multiple/variant/custom
    # coercers, every stock validator, oneof variants, lateral (given) and
    # nested scopes.
    let(:app) do
      ct = custom_type
      Class.new(Grape::API) do
        format :json

        params do
          requires :id, type: Integer
          optional :ids, type: Array[Integer]
          optional :matrix, type: Array[Array[Integer]]
          optional :tags, type: Set[Integer]
          optional :multi, type: [Integer, String]
          optional :kinds, types: [Integer, String]
          optional :custom, type: ct
          optional :customs, type: Array[ct]
          optional :stripped, type: String, coerce_with: lambda(&:strip)
          optional :state, type: String, values: %w[a b], default: 'a'
          optional :lazy, type: Integer, values: -> { [1, 2] }
          optional :not_these, type: Integer, except_values: [99]
          optional :code, type: String, regexp: /\A[a-z]+\z/, length: { min: 1, max: 10 }
          optional :pw, type: String
          optional :pw2, type: String, same_as: :pw, allow_blank: false
          mutually_exclusive :custom, :stripped
          at_least_one_of :id, :ids
        end
        post('/all') { 'ok' }

        params do
          requires :doc, type: JSON do
            requires :name, type: String
          end
          requires :root, type: Hash do
            requires :inner, type: Array do
              requires :leaf, type: String
            end
          end
          optional :variant, type: Hash, oneof: [
            proc { requires :x, type: Integer },
            proc { requires :y, type: String }
          ]
          optional :mode, type: String
          given :mode do
            requires :detail, type: String
          end
        end
        post('/nested') { 'ok' }
      end
    end

    # Classes whose instances are shared across requests and must be frozen.
    def frozen_contract_classes
      [
        Grape::Validations::Validators::Base,
        Grape::Validations::Validators::ContractScopeValidator,
        Grape::Validations::AttributesIterator,
        Grape::Validations::ParamsScope,
        Grape::Validations::Types::DryTypeCoercer,
        Grape::Validations::Types::CustomTypeCoercer,
        Grape::Validations::Types::MultipleTypeCoercer,
        Grape::Validations::Types::VariantCollectionCoercer
      ]
    end

    # Walks ivars and collection members. Skips value types, callables
    # (user-supplied procs are deliberately unfrozen), open classes/modules,
    # and dry-types internals (external library, outside grape's contract).
    def walk(obj, path, seen, violations, census)
      case obj
      when Module, Proc, Method, UnboundMethod, Symbol, Numeric, Range, Regexp, true, false, nil
        return
      end
      return if obj.class.name&.start_with?('Dry::')
      return if seen.key?(obj)

      seen[obj] = true
      if frozen_contract_classes.any? { |klass| obj.is_a?(klass) }
        census[obj.class] += 1
        violations << "#{path} (#{obj.class})" unless obj.frozen?
      end
      walk_members(obj, path, seen, violations, census)
    end

    def walk_members(obj, path, seen, violations, census)
      case obj
      when Hash
        obj.each do |k, v|
          walk(k, "#{path}.key(#{k.inspect[0, 30]})", seen, violations, census)
          walk(v, "#{path}[#{k.inspect[0, 30]}]", seen, violations, census)
        end
      when Array, Set
        obj.each_with_index { |e, i| walk(e, "#{path}[#{i}]", seen, violations, census) }
      else
        obj.instance_variables.each do |ivar|
          walk(obj.instance_variable_get(ivar), "#{path}.#{ivar}", seen, violations, census)
        end
      end
    end

    def walk_route_validations(api)
      violations = []
      census = Hash.new(0)
      seen = {}.compare_by_identity
      api.endpoints.each_with_index do |endpoint, i|
        Array(endpoint.inheritable_setting.route[:validations]).each_with_index do |validator, j|
          walk(validator, "endpoint[#{i}].validator[#{j}]", seen, violations, census)
        end
      end
      [violations, census]
    end

    it 'freezes every validator, iterator, scope and coercer reachable from the routes' do
      violations, census = walk_route_validations(app)

      expect(violations).to be_empty, "unfrozen shared objects:\n  #{violations.join("\n  ")}"

      # The walk must actually have swept the taxonomy — an empty walk would
      # pass vacuously. Presence of these classes proves coverage, including
      # oneof variant validators reached through nested walking.
      expect(census.keys).to include(
        Grape::Validations::Validators::PresenceValidator,
        Grape::Validations::Validators::CoerceValidator,
        Grape::Validations::Validators::ValuesValidator,
        Grape::Validations::Validators::OneofValidator,
        Grape::Validations::Validators::MutuallyExclusiveValidator,
        Grape::Validations::SingleAttributeIterator,
        Grape::Validations::MultipleAttributesIterator,
        Grape::Validations::ParamsScope,
        Grape::Validations::Types::PrimitiveCoercer,
        Grape::Validations::Types::ArrayCoercer,
        Grape::Validations::Types::SetCoercer,
        Grape::Validations::Types::CustomTypeCoercer,
        Grape::Validations::Types::CustomTypeCollectionCoercer,
        Grape::Validations::Types::MultipleTypeCoercer,
        Grape::Validations::Types::VariantCollectionCoercer
      )
    end

    it 'reports an unfrozen contract instance (walker self-test)' do
      scope = app.endpoints.first.inheritable_setting.route[:validations].first.__send__(:scope)
      unfrozen = Grape::Validations::SingleAttributeIterator.new([:a], scope)

      violations = []
      walk(unfrozen, 'probe', {}.compare_by_identity, violations, Hash.new(0))

      expect(violations).to contain_exactly("probe (#{unfrozen.class})")
    end
  end
end
