# frozen_string_literal: true

# only exists to make it shorter for external use
module Grape
  module Types
    InvalidValue = Class.new(Grape::Validations::Types::InvalidValue)
  end
end
