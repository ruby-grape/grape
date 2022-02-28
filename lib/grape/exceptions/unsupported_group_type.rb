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

Grape::Exceptions::UnsupportedGroupTypeError = Class.new(Grape::Exceptions::UnsupportedGroupType) do
  def initialize(*)
    super
    warn '[DEPRECATION] `Grape::Exceptions::UnsupportedGroupTypeError` is deprecated. Use `Grape::Exceptions::UnsupportedGroupType` instead.'
  end
end
