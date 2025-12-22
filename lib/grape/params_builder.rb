# frozen_string_literal: true

module Grape
  module ParamsBuilder
    extend Grape::Util::Registry

    module_function

    def params_builder_for(short_name)
      raise Grape::Exceptions::UnknownParamsBuilder, short_name unless registry.key?(short_name)

      registry[short_name]
    end
  end
end
