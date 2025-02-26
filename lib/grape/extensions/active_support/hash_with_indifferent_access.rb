# frozen_string_literal: true

module Grape
  module Extensions
    module ActiveSupport
      module HashWithIndifferentAccess
        module ParamBuilder
          extend ::ActiveSupport::Concern

          included do
            Grape.deprecator.warn 'This concern has been deprecated. Use `build_with` with one of the following short_name (:hash, :hash_with_indifferent_access, :hashie_mash) instead.'
            namespace_inheritable(:build_params_with, :hash_with_indifferent_access)
          end

          def build_params
            ::ActiveSupport::HashWithIndifferentAccess.new(rack_params).tap do |params|
              params.deep_merge!(grape_routing_args) if env.key?(Grape::Env::GRAPE_ROUTING_ARGS)
            end
          end
        end
      end
    end
  end
end
