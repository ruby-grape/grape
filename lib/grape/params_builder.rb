# frozen_string_literal: true

module Grape
  module ParamsBuilder
    extend Grape::Util::Registry

    SHORT_NAME_LOOKUP = {
      'Grape::Extensions::Hash::ParamBuilder' => :hash,
      'Grape::Extensions::ActiveSupport::HashWithIndifferentAccess::ParamBuilder' => :hash_with_indifferent_access,
      'Grape::Extensions::Hashie::Mash::ParamBuilder' => :hashie_mash
    }.freeze

    module_function

    def params_builder_for(short_name)
      verified_short_name = verify_short_name!(short_name)

      raise Grape::Exceptions::UnknownParamsBuilder, verified_short_name unless registry.key?(verified_short_name)

      registry[verified_short_name]
    end

    def verify_short_name!(short_name)
      return short_name if short_name.is_a?(Symbol)

      class_name = short_name.name
      SHORT_NAME_LOOKUP[class_name].tap do |real_short_name|
        Grape.deprecator.warn "#{class_name} has been deprecated. Use short name :#{real_short_name} instead."
      end
    end
  end
end
