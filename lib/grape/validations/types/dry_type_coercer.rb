# frozen_string_literal: true

require 'dry-types'

module DryTypes
  # Call +Dry.Types()+ to add all registered types to +DryTypes+ which is
  # a container in this case. Check documentation for more information
  # https://dry-rb.org/gems/dry-types/1.2/getting-started/
  include Dry.Types()
end

module Grape
  module Validations
    module Types
      # A base class for classes which must identify a coercer to be used.
      # If the +strict+ argument is true, it won't coerce the given value
      # but check its type. More information there
      # https://dry-rb.org/gems/dry-types/1.2/built-in-types/
      class DryTypeCoercer
        def initialize(type, strict = false)
          @type = type
          @scope = strict ? DryTypes::Strict : DryTypes::Params
        end

        # Coerces the given value to a type which was specified during
        # initialization as a type argument.
        #
        # @param val [Object]
        def call(val)
          @coercer[val]
        rescue Dry::Types::CoercionError => _e
          InvalidValue.new
        end

        protected

        attr_reader :scope, :type
      end
    end
  end
end
