# frozen_string_literal: true

module Grape
  module Exceptions
    class MissingGroupType < Base
      def initialize
        super(message: compose_message(:missing_group_type))
      end
    end
  end
end

Grape::Exceptions::MissingGroupTypeError = ActiveSupport::Deprecation::DeprecatedConstantProxy.new('Grape::Exceptions::MissingGroupTypeError', 'Grape::Exceptions::MissingGroupType', Grape.deprecator)
