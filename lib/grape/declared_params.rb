# frozen_string_literal: true

module Grape
  # The params an endpoint declares, as +declared+ filters a Hash by them.
  #
  # What +declared+ answers for a param depends on the request only for its
  # value. The key it is filed under -- its name, or the one +as:+ renamed it
  # to -- and the empty value it stands for when it was not passed -- an
  # Array, a Set or a Hash, after its documented type -- are settled by the
  # declaration. Both were worked out again on every call, for every param:
  # the path to the param built to look its new name up, its documented name
  # spelled out to look its type up, that type matched against the ones that
  # have an empty value. They are worked out here once, when the endpoint
  # compiles, as Validations::UndeclaredParams is.
  class DeclaredParams
    extend Grape::Util::FreezeOnNew

    # A declared param: the +name+ it is read by, the +key+ and +string_key+
    # it is filed under, the params declared under it (+children+, nil for a
    # param declared without a block), the +empty_value+ it stands for when
    # it was not passed (nil when its type has none), and the +scope+ that
    # declared it, whose +given+ +evaluate_given+ asks about.
    Param = Data.define(:name, :key, :string_key, :children, :empty_value, :scope)

    EMPTY_HASH = {}.freeze
    EMPTY_ARRAY = [].freeze
    EMPTY_SET = Set.new.freeze
    private_constant :EMPTY_HASH, :EMPTY_ARRAY, :EMPTY_SET

    # +all+ are the params of the endpoint and of its namespaces, +own+ the
    # ones of the endpoint's own +params+ block, which is what
    # +include_parent_namespaces: false+ keeps.
    attr_reader :all, :own, :contract_key_maps

    # @param declared_params [Array<Validations::ParamsScope::Attr>] the
    #   endpoint's declared params, its namespaces' included
    # @param own_declared_params [Array<Validations::ParamsScope::Attr>, nil]
    #   the ones its own +params+ block declares, nil when none was
    # @param route_params [Hash] the endpoint's documented params, by full name
    # @param renamed_params [Hash] the names +as:+ gave, by the path of the
    #   param they rename
    # @param contract_key_maps [Array<Dry::Schema::KeyMap>] the keys of the
    #   endpoint's contracts
    def initialize(declared_params:, own_declared_params:, route_params:, renamed_params:, contract_key_maps:)
      compiler = Compiler.new(route_params:, renamed_params:)
      @all = compiler.call(declared_params)
      @own = own_declared_params ? compiler.call(own_declared_params) : EMPTY_ARRAY
      @contract_key_maps = contract_key_maps
    end

    # Works out the Params of ParamsScope::Attrs from what the route documents
    # of them. It holds what only compiling reads, and is dropped once the
    # endpoint has compiled, so none of it stays with the DeclaredParams.
    class Compiler
      def initialize(route_params:, renamed_params:)
        @route_params = route_params
        @renamed_params = renamed_params
        # An endpoint's own params are among all of them, and compile once.
        @compiled = Hash.new { |memo, attr| memo[attr] = compile(attr) }.compare_by_identity
      end

      # @param attrs [Array<Validations::ParamsScope::Attr>]
      # @return [Array<Param>]
      def call(attrs)
        attrs.flat_map(&@compiled).freeze
      end

      private

      # The params of a ParamsScope::Attr, whose key is a name, or a Hash of
      # names to the Attrs declared under them. +parent_name+ is the enclosing
      # param as the route documents it (+"a[b]"+) and +parent_path+ the names
      # leading to it (+%w[a b]+), both nil at the root.
      def compile(attr, parent_name = nil, parent_path = nil)
        declared = attr.key
        return [param(declared, attr.scope, parent_name, parent_path)] unless declared.is_a?(Hash)

        declared.map { |name, children| param(name, attr.scope, parent_name, parent_path, children) }
      end

      def param(name, scope, parent_name, parent_path, children = nil)
        path = [*parent_path, name.to_s]
        full_name = parent_name ? "#{parent_name}[#{name}]" : name.to_s
        key = @renamed_params[path] || name
        Param.new(
          name:,
          # A name read from +configuration+ is nil until the API is mounted
          # with one, and an API compiles unmounted too.
          key: key.respond_to?(:to_sym) ? key.to_sym : key,
          string_key: -key.to_s,
          children: children&.flat_map { |child| compile(child, full_name, path) }.freeze,
          empty_value: empty_value_for(full_name),
          scope:
        )
      end

      # A Hash is only empty when no param is declared under it: one that
      # declares some stands for a Hash of them instead, each nil or empty in
      # turn.
      def empty_value_for(full_name)
        type = documented_type(full_name)
        return unless type
        return EMPTY_HASH if type == 'Hash' && no_child_params?("#{full_name}[")
        return EMPTY_ARRAY if array_type?(type)

        EMPTY_SET if type.start_with?('#<Set', 'Set')
      end

      # Nil for a type that is not spelled as a String, which has no empty
      # value: a +desc+ may document a param of its own with a Class, or with
      # no Hash of details at all.
      def documented_type(full_name)
        details = @route_params[full_name]
        type = details[:type] if details.is_a?(Hash)
        type if type.is_a?(String)
      end

      # +Array+ and +Array[String]+, but not the Array of types a param
      # declared with +types:+ documents.
      def array_type?(type)
        type == 'Array' || (type.start_with?('[') && !type.include?(','))
      end

      def no_child_params?(prefix)
        documented_names.none? { |documented| documented.start_with?(prefix) }
      end

      # Spelled out only once a Hash param asks: a +desc+ documents params
      # under whatever keys it was given, a Symbol or an Integer too.
      def documented_names
        @documented_names ||= @route_params.keys.map(&:to_s)
      end
    end
    private_constant :Compiler
  end
end
