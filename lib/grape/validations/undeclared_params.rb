# frozen_string_literal: true

module Grape
  module Validations
    # The params of a request that its endpoint did not declare, answered 400
    # when +Grape.config.allow_undeclared_params+ is false.
    #
    # The names an endpoint declares -- with +requires+ and +optional+, in its
    # own +params+ block and its namespaces', as a +contract+'s keys, or as a
    # segment of its path -- are folded into a tree once, when the endpoint
    # compiles. Each name maps to the tree of the names declared under it, or
    # to nil when nothing is: a param declared without a block (a +File+, a
    # +type: Hash+ or +JSON+ without one, a +oneof:+) takes whatever it is
    # given, and is left to its validators.
    class UndeclaredParams
      extend Grape::Util::FreezeOnNew

      # Read by Grape itself rather than by an endpoint: the formatter takes
      # the response format from it. See Middleware::Formatter#format_from_query.
      GRAPE_PARAMS = [Grape::Middleware::Formatter::FORMAT_PARAM].freeze

      # What the tree answers for a name it does not hold, where nil is a name
      # declared without children.
      UNDECLARED = Object.new.freeze
      private_constant :UNDECLARED

      # @param declared_params [Array<ParamsScope::Attr>] the endpoint's
      #   declared params, its namespaces' included
      # @param contract_key_maps [Array<Dry::Schema::KeyMap>] the keys of the
      #   endpoint's contracts
      # @param path_params [Array<String>] the names its routes capture
      def initialize(declared_params:, contract_key_maps:, path_params:)
        tree = {}
        [*GRAPE_PARAMS, *path_params].each { |name| tree[name] = nil }
        declared_params.each { |attr| declared_entries(attr.key).each { |entry| add(tree, *entry) } }
        contract_key_maps.each { |key_map| key_map.dump.each { |spec| add(tree, *contract_entry(spec)) } }
        @tree = Grape::Util::DeepFreeze.deep_freeze(tree)
      end

      # @param request [Grape::Request]
      # @param validation_exceptions [Array<Grape::Exceptions::Validation,
      #   Grape::Exceptions::ValidationArrayErrors>, nil] what the endpoint's
      #   validators raised for +request+, nil when they raised nothing
      # @return [Array<Grape::Exceptions::Validation>, nil] one error for each
      #   param of +request+ that is not declared, but for those inside a param
      #   the validators rejected; nil when it sent only declared params
      def errors(request, validation_exceptions)
        return unless request.params_sent?

        paths = undeclared_in(request.params, @tree)
        return unless paths

        names = paths.map { |path| full_name(path) }
        names = unreported(names, validation_exceptions) if validation_exceptions
        names.map { |name| Grape::Exceptions::Validation.new(params: name, message: :undeclared) }
      end

      private

      # A param the validators rejected is not looked into as well: an Array
      # sent a Hash, say, is invalid, and each key of that Hash was named after
      # it, as though the Hash were one of its elements. The request is
      # answered 400 either way.
      def unreported(names, validation_exceptions)
        errors = validation_exceptions.flat_map(&:errors)
        names.reject do |name|
          errors.any? { |error| error.params.any? { |param| name.start_with?("#{param}[") } }
        end
      end

      # +children+ are the +[name, children]+ entries declared under +name+, or
      # nil when it is declared without any. Two declarations of a name with
      # children add up, and one without any accepts anything, whichever comes
      # first.
      def add(tree, name, children)
        return tree[name] = nil unless children

        subtree = tree.key?(name) ? tree[name] : (tree[name] = {})
        children.each { |entry| add(subtree, *entry) } if subtree
      end

      # The entries of a ParamsScope::Attr's key: a name, or a Hash of names
      # to the Attrs declared under them.
      def declared_entries(key)
        return [[key.to_s, nil]] unless key.is_a?(Hash)

        key.map { |name, attrs| [name.to_s, attrs.flat_map { |attr| declared_entries(attr.key) }] }
      end

      # The entry of a key in Dry::Schema::KeyMap#dump's format: a name, a
      # +{ name => [spec] }+ Hash, or a +[name, [spec]]+ pair for an Array of
      # Hashes.
      def contract_entry(spec)
        return [spec.to_s, nil] unless spec.is_a?(Hash) || spec.is_a?(Array)

        name, children = spec.is_a?(Hash) ? spec.first : spec
        [name.to_s, children.map { |child| contract_entry(child) }]
      end

      # The paths, relative to +value+, of what +value+ holds that +tree+ does
      # not declare, as Arrays of names and indexes; nil when there is none.
      # They are built only once one is found, so a request that declares
      # everything it sends allocates nothing here.
      def undeclared_in(value, tree)
        return undeclared_in_elements(value, tree) if value.is_a?(Array)

        undeclared_in_hash(value, tree) if value.is_a?(Hash)
      end

      def undeclared_in_hash(hash, tree)
        found = nil
        hash.each_pair do |key, value|
          name = key.is_a?(Symbol) ? key.name : key
          subtree = tree.fetch(name, UNDECLARED)
          next unless subtree

          paths = subtree.equal?(UNDECLARED) ? [[name]] : prefixed(name, undeclared_in(value, subtree))
          (found ||= []).concat(paths) if paths
        end
        found
      end

      def undeclared_in_elements(elements, tree)
        found = nil
        elements.each_with_index do |element, index|
          paths = prefixed(index, undeclared_in(element, tree))
          (found ||= []).concat(paths) if paths
        end
        found
      end

      def prefixed(segment, paths)
        paths&.each { |path| path.unshift(segment) }
      end

      def full_name(path)
        first, *rest = path
        rest.empty? ? first.to_s : "#{first}[#{rest.join('][')}]"
      end
    end
  end
end
