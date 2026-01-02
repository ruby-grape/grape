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
        declared_params: declared_params,
        route_params: route_params,
        renamed_params: renamed_params
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
      if declared_param.is_a?(Hash)
        declared_param.each_pair do |declared_parent_param, declared_children_params|
          next unless @include_missing || passed_params.key?(declared_parent_param)

          memo_key = build_memo_key(params_nested_path, declared_parent_param, renamed_params)
          passed_children_params = passed_params[declared_parent_param] || passed_params.class.new

          params_nested_path_dup = params_nested_path.dup
          params_nested_path_dup << declared_parent_param.to_s

          memo[memo_key] = handle_passed_param(params_nested_path_dup, route_params:, has_passed_children: passed_children_params.any?) do
            recursive_declared(
              passed_children_params,
              declared_params: declared_children_params,
              params_nested_path: params_nested_path_dup,
              renamed_params:,
              route_params:
            )
          end
        end
      else
        # If it is not a Hash then it does not have children.
        # Find its value or set it to nil.
        return unless @include_missing || (passed_params.respond_to?(:key?) && passed_params.key?(declared_param))

        memo_key = build_memo_key(params_nested_path, declared_param, renamed_params)
        passed_param = passed_params[declared_param]

        params_nested_path_dup = params_nested_path.dup
        params_nested_path_dup << declared_param.to_s

        memo[memo_key] = passed_param || handle_passed_param(params_nested_path_dup, route_params:) do
          passed_param
        end
      end
    end

    def build_memo_key(params_nested_path, declared_param, renamed_params)
      rename_path = params_nested_path + [declared_param.to_s]
      renamed_param_name = renamed_params[rename_path]

      param = renamed_param_name || declared_param
      @stringify ? param.to_s : param.to_sym
    end

    def handle_passed_param(params_nested_path, route_params:, has_passed_children: false, &_block)
      return yield if has_passed_children

      key = params_nested_path[0]
      key += "[#{params_nested_path[1..].join('][')}]" if params_nested_path.size > 1

      type = route_params.dig(key, :type)
      has_children = route_params.keys.any? { |k| k != key && k.start_with?("#{key}[") }

      if type == 'Hash' && !has_children
        {}
      elsif type == 'Array' || (type&.start_with?('[') && !type.include?(','))
        []
      elsif type == 'Set' || type&.start_with?('#<Set', 'Set')
        Set.new
      else
        yield
      end
    end
  end
end
