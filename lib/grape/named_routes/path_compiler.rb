module Grape
  module NamedRoutes
    module PathCompiler
      class << self
        # this method substitutes given params to route path
        def compile_path(route, params = {})
          path_with_optional_params = substitute_optional_params(route.route_path, params)
          substitute_required_params(path_with_optional_params, params)
        end

        private

        def substitute_optional_params(path, params)
          # explanation for regexp below: we seek parenthesis
          # with string like :string in them (possibly appended and/or prepended with smth)
          #
          # for example, for string '/api/statuses/:id/(.:format)'
          #   match[1] will be '.'
          #   match[2] will be param_value(params, format)
          #   match[3] will be nil
          #
          # It could be rewrote with $1,$2,$3, but Rubocop doesn't like these variables
          optional_params_regexp = /\((.*):(\w+)(.*)\)/

          path.gsub(optional_params_regexp) do
            match = Regexp.last_match
            value = param_value(params, match[2])
            [match[1], value, match[3]].join if value
          end
        end

        def substitute_required_params(path, params)
          path.gsub(/:(\w+)/) do
            param = Regexp.last_match[1]
            value = param_value(params, param)
            unless value
              fail Grape::NamedRoutes::MissedRequiredParam.new(param), "Required param '#{param}' is missed."
            end
            value
          end
        end

        def param_value(params, param)
          params[param] || params[param.to_sym]
        end
      end
    end
  end
end
