# frozen_string_literal: true

module Grape
  # @deprecated +Grape::Path+ moved to {Grape::Router::Pattern::Path}, since it
  #   is a router-internal detail that only exists to build a
  #   {Grape::Router::Pattern}. Reference the new constant instead.
  Path = ActiveSupport::Deprecation::DeprecatedConstantProxy.new(
    'Grape::Path',
    'Grape::Router::Pattern::Path',
    Grape.deprecator
  )
end
