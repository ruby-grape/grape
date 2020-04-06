# frozen_string_literal: true

module Grape
  module Validations
    module Types
      # Handles coercion and type checking for parameters that are subclasses
      # of Grape::Entity.
      class GrapeEntityCoercer
        def initialize(type)
          @type = type
        end

        def call(val)
          return if val.nil?

          return InvalidValue.new unless coerced?(val)
        end

        private

        attr_reader :type

        def coerced?(val)
          val.each_key do |k|
            exposure = type.find_exposure(k.to_sym)
            return false unless exposure
          end
        end
      end
    end
  end
end
