# frozen_string_literal: true

module Grape
  module Util
    module Lazy
      class ValueHash < ValueEnumerable
        def initialize(hash)
          super
          @value_hash = ActiveSupport::HashWithIndifferentAccess.new
          hash.each do |key, value|
            self[key] = value
          end
        end

        def evaluate
          @value_hash.transform_values(&:evaluate)
        end
      end
    end
  end
end
