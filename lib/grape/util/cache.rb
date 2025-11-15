# frozen_string_literal: true

module Grape
  module Util
    class Cache
      include Singleton

      attr_reader :cache

      class << self
        extend Forwardable

        def_delegators :cache, :[]
        def_delegators :instance, :cache
      end
    end
  end
end
