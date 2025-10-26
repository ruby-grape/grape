# frozen_string_literal: true

module Grape
  module ParamsBuilder
    class Base
      class << self
        def call(_params)
          raise NotImplementedError
        end

        private

        def inherited(klass)
          super
          ParamsBuilder.register(klass)
        end
      end
    end
  end
end
