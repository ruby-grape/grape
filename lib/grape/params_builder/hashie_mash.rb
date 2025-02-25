# frozen_string_literal: true

module Grape
  module ParamsBuilder
    class HashieMash < Base
      def self.call(params)
        ::Hashie::Mash.new(params)
      end
    end
  end
end
