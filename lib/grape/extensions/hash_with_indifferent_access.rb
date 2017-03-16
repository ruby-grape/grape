module Grape
  module Extensions
    module HashWithIndifferentAccess
      def params_builder
        Grape::Extensions::HashWithIndifferentAccess::ParamBuilder
      end

      module ParamBuilder
        def build_params
          params = ActiveSupport::HashWithIndifferentAccess[rack_params]
          params.deep_merge!(grape_routing_args) if env[Grape::Env::GRAPE_ROUTING_ARGS]
          params
        end
      end
    end
  end
end
