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

Grape::Exceptions::MissingGroupTypeError = Class.new(Grape::Exceptions::MissingGroupType) do
  def initialize(*)
    super
    warn '[DEPRECATION] `Grape::Exceptions::MissingGroupTypeError` is deprecated. Use `Grape::Exceptions::MissingGroupType` instead.'
  end
end
