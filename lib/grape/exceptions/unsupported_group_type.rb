# frozen_string_literal: true

module Grape
  module Exceptions
    class UnsupportedGroupType < Base
      def initialize
        super(message: compose_message(:unsupported_group_type))
      end
    end
  end
end

Grape::Exceptions::UnsupportedGroupTypeError = ActiveSupport::Deprecation::DeprecatedConstantProxy.new('Grape::Exceptions::UnsupportedGroupTypeError', 'Grape::Exceptions::UnsupportedGroupType', Grape.deprecator)
