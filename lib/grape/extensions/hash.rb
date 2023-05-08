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
            params.deep_merge!(grape_routing_args) if env.key?(Grape::Env::GRAPE_ROUTING_ARGS)
            params.deep_symbolize_keys!
          end
        end
      end
    end
  end
end
