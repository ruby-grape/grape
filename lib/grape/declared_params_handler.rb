# frozen_string_literal: true

module Grape
  class DeclaredParamsHandler
    def initialize(include_missing: true, evaluate_given: false, stringify: false, contract_key_map: nil)
      @include_missing = include_missing
      @evaluate_given = evaluate_given
      @stringify = stringify
      @contract_key_map = contract_key_map
    end

    def call(passed_params, declared_params, route_params, renamed_params)
      recursive_declared(
        passed_params,
        declared_params:,
        route_params:,
        renamed_params:
      )
    end

    private

    def recursive_declared(passed_params, declared_params:, route_params:, renamed_params:, params_nested_path: [])
      res = if passed_params.is_a?(Array)
              passed_params.map do |passed_param|
                recursive_declared(passed_param, declared_params:, params_nested_path:, renamed_params:, route_params:)
              end
            else
              declared_hash(passed_params, declared_params:, params_nested_path:, renamed_params:, route_params:)
            end

      @contract_key_map&.each { |key_map| key_map.write(passed_params, res) }

      res
    end

    def declared_hash(passed_params, declared_params:, params_nested_path:, renamed_params:, route_params:)
      declared_params.each_with_object(passed_params.class.new) do |declared_param_attr, memo|
        next if @evaluate_given && !declared_param_attr.scope.attr_meets_dependency?(passed_params)

        declared_hash_attr(
          passed_params,
          declared_param: declared_param_attr.key,
          params_nested_path:,
          memo:,
          renamed_params:,
          route_params:
        )
      end
    end

    def declared_hash_attr(passed_params, declared_param:, params_nested_path:, memo:, renamed_params:, route_params:)
      return declare_leaf(passed_params, declared_param:, params_nested_path:, memo:, renamed_params:, route_params:) unless declared_param.is_a?(Hash)

      declared_param.each_pair do |parent, children|
        declare_nested(passed_params, parent:, children:, params_nested_path:, memo:, renamed_params:, route_params:)
      end
    end

    def declare_nested(passed_params, parent:, children:, params_nested_path:, memo:, renamed_params:, route_params:)
      return unless @include_missing || passed_params.key?(parent)

      memo_key = build_memo_key(params_nested_path, parent, renamed_params)
      passed_children = passed_params[parent] || passed_params.class.new
      nested_path = nested_path_for(params_nested_path, parent)

      memo[memo_key] = handle_passed_param(nested_path, route_params:, has_passed_children: passed_children.any?) do
        recursive_declared(
          passed_children,
          declared_params: children,
          params_nested_path: nested_path,
          renamed_params:,
          route_params:
        )
      end
    end

    # The declared param has no children. Find its value or set it to nil.
    def declare_leaf(passed_params, declared_param:, params_nested_path:, memo:, renamed_params:, route_params:)
      return unless @include_missing || (passed_params.respond_to?(:key?) && passed_params.key?(declared_param))

      memo_key = build_memo_key(params_nested_path, declared_param, renamed_params)
      passed_param = passed_params[declared_param]

      memo[memo_key] = passed_param || handle_passed_param(nested_path_for(params_nested_path, declared_param), route_params:) do
        passed_param
      end
    end

    def build_memo_key(params_nested_path, declared_param, renamed_params)
      renamed_param_name = renamed_params[nested_path_for(params_nested_path, declared_param)]
      param = renamed_param_name || declared_param
      @stringify ? param.to_s : param.to_sym
    end

    def nested_path_for(parent_path, key)
      parent_path + [key.to_s]
    end

    def handle_passed_param(params_nested_path, route_params:, has_passed_children: false)
      return yield if has_passed_children

      key = params_nested_path.first
      key += "[#{params_nested_path[1..].join('][')}]" if params_nested_path.size > 1

      type = route_params.dig(key, :type)
      return yield if type.nil?

      return {} if type == 'Hash' && route_params.keys.none? { |k| k != key && k.start_with?("#{key}[") }
      return [] if type == 'Array' || (type.start_with?('[') && !type.include?(','))
      return Set.new if type == 'Set' || type.start_with?('#<Set', 'Set')

      yield
    end
  end
end
