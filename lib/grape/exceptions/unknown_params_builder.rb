# frozen_string_literal: true

module Grape
  module Exceptions
    class UnknownParamsBuilder < Base
      def initialize(params_builder_type)
        super(message: compose_message(:unknown_params_builder, params_builder_type: params_builder_type))
      end
    end
  end
end
