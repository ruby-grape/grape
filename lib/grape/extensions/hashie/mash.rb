module Grape
  module Extensions
    module Hashie
      module Mash
        def params_builder
          Grape::Extensions::Hashie::Mash::ParamBuilder
        end

        module ParamBuilder
          def build_params
            params = ::Hashie::Mash.new(rack_params)
            params.deep_merge!(grape_routing_args) if env[Grape::Env::GRAPE_ROUTING_ARGS]
            params
          end
        end
      end
    end
  end
end
