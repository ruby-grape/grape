# frozen_string_literal: true

module Grape
  module ParamsBuilder
    class HashWithIndifferentAccess < Base
      def self.call(params)
        ActiveSupport::HashWithIndifferentAccess.new(params)
      end
    end
  end
end
