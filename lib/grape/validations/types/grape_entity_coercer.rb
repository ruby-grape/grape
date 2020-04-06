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

          if val.is_a?(Array)
            val.each do |i|
              return InvalidValue.new unless coerced?(i)
            end
          else
            return InvalidValue.new unless coerced?(val)
          end
        end

        private

        attr_reader :type

        def coerced?(val)
          val.each_key do |k|
            return false unless exposure_keys.include?(k.to_sym)
          end

          true
        end

        def exposure_keys
          type.root_exposures.map(&:key)
        end
      end
    end
  end
end
