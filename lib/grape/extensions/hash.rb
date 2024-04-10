# frozen_string_literal: true

module Grape
  module Extensions
    module Hash
      module ParamBuilder
        extend ::ActiveSupport::Concern

        included do
          namespace_inheritable(:build_params_with, Grape::Extensions::Hash::ParamBuilder)
        end

        def build_params
          rack_params.deep_dup.tap do |params|
            params.deep_symbolize_keys!

            if env.key?(Grape::Env::GRAPE_ROUTING_ARGS)
              grape_routing_args.deep_symbolize_keys!
              params.deep_merge!(grape_routing_args)
            end
          end
        end
      end
    end
  end
end
