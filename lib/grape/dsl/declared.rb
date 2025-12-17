# frozen_string_literal: true

module Grape
  module DSL
    module Declared
      # Denotes a situation where a DSL method has been invoked in a
      # filter which it should not yet be available in
      class MethodNotYetAvailable < StandardError
        def initialize(msg = '#declared is not available prior to parameter validation')
          super
        end
      end

      # A filtering method that will return a hash
      # consisting only of keys that have been declared by a
      # `params` statement against the current/target endpoint or parent
      # namespaces.
      # @param params [Hash] The initial hash to filter. Usually this will just be `params`
      # @param options [Hash] Can pass `:include_missing`, `:stringify` and `:include_parent_namespaces`
      # options. `:include_parent_namespaces` defaults to true, hence must be set to false if
      # you want only to return params declared against the current/target endpoint.
      def declared(passed_params, options = {}, declared_params = nil, params_nested_path = [])
        raise MethodNotYetAvailable unless before_filter_passed

        options.reverse_merge!(include_missing: true, include_parent_namespaces: true, evaluate_given: false)
        declared_params ||= optioned_declared_params(options[:include_parent_namespaces])

        res = if passed_params.is_a?(Array)
                declared_array(passed_params, options, declared_params, params_nested_path)
              else
                declared_hash(passed_params, options, declared_params, params_nested_path)
              end

        if (key_maps = inheritable_setting.namespace_stackable[:contract_key_map])
          key_maps.each { |key_map| key_map.write(passed_params, res) }
        end

        res
      end

      private

      def declared_array(passed_params, options, declared_params, params_nested_path)
        passed_params.map do |passed_param|
          declared(passed_param || {}, options, declared_params, params_nested_path)
        end
      end

      def declared_hash(passed_params, options, declared_params, params_nested_path)
        declared_params.each_with_object(passed_params.class.new) do |declared_param_attr, memo|
          next if options[:evaluate_given] && !declared_param_attr.scope.attr_meets_dependency?(passed_params)

          declared_hash_attr(passed_params, options, declared_param_attr.key, params_nested_path, memo)
        end
      end

      def declared_hash_attr(passed_params, options, declared_param, params_nested_path, memo)
        renamed_params = inheritable_setting.route[:renamed_params] || {}
        if declared_param.is_a?(Hash)
          declared_param.each_pair do |declared_parent_param, declared_children_params|
            params_nested_path_dup = params_nested_path.dup
            params_nested_path_dup << declared_parent_param.to_s
            next unless options[:include_missing] || passed_params.key?(declared_parent_param)

            rename_path = params_nested_path + [declared_parent_param.to_s]
            renamed_param_name = renamed_params[rename_path]

            memo_key = optioned_param_key(renamed_param_name || declared_parent_param, options)
            passed_children_params = passed_params[declared_parent_param] || passed_params.class.new

            memo[memo_key] = handle_passed_param(params_nested_path_dup, has_passed_children: passed_children_params.any?) do
              declared(passed_children_params, options, declared_children_params, params_nested_path_dup)
            end
          end
        else
          # If it is not a Hash then it does not have children.
          # Find its value or set it to nil.
          return unless options[:include_missing] || (passed_params.respond_to?(:key?) && passed_params.key?(declared_param))

          rename_path = params_nested_path + [declared_param.to_s]
          renamed_param_name = renamed_params[rename_path]

          memo_key = optioned_param_key(renamed_param_name || declared_param, options)
          passed_param = passed_params[declared_param]

          params_nested_path_dup = params_nested_path.dup
          params_nested_path_dup << declared_param.to_s
          memo[memo_key] = passed_param || handle_passed_param(params_nested_path_dup) do
            passed_param
          end
        end
      end

      def handle_passed_param(params_nested_path, has_passed_children: false, &_block)
        return yield if has_passed_children

        key = params_nested_path[0]
        key += "[#{params_nested_path[1..].join('][')}]" if params_nested_path.size > 1

        route_options_params = options[:route_options][:params] || {}
        type = route_options_params.dig(key, :type)
        has_children = route_options_params.keys.any? { |k| k != key && k.start_with?("#{key}[") }

        if type == 'Hash' && !has_children
          {}
        elsif type == 'Array' || (type&.start_with?('[') && !type.include?(','))
          []
        elsif type == 'Set' || type&.start_with?('#<Set')
          Set.new
        else
          yield
        end
      end

      def optioned_param_key(declared_param, options)
        options[:stringify] ? declared_param.to_s : declared_param.to_sym
      end

      def optioned_declared_params(include_parent_namespaces)
        declared_params = if include_parent_namespaces
                            # Declared params including parent namespaces
                            inheritable_setting.route[:declared_params]
                          else
                            # Declared params at current namespace
                            inheritable_setting.namespace_stackable[:declared_params].last || []
                          end

        raise ArgumentError, 'Tried to filter for declared parameters but none exist.' unless declared_params

        declared_params
      end
    end
  end
end
