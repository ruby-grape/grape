# frozen_string_literal: true

module Grape
  module ParamsBuilder
    class Hash < Base
      def self.call(params)
        params.deep_symbolize_keys
      end
    end
  end
end
