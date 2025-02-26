# frozen_string_literal: true

module Grape
  module ParamsBuilder
    class HashWithIndifferentAccess < Base
      def self.call(params)
        params.with_indifferent_access
      end
    end
  end
end
