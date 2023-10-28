# frozen_string_literal: true

module Grape
  module Util
    class LazyValueEnumerable < LazyValue
      def [](key)
        if @value_hash[key].nil?
          LazyValue.new(nil).reached_by(access_keys, key)
        else
          @value_hash[key].reached_by(access_keys, key)
        end
      end

      def fetch(access_keys)
        fetched_keys = access_keys.dup
        value = self[fetched_keys.shift]
        fetched_keys.any? ? value.fetch(fetched_keys) : value
      end

      def []=(key, value)
        @value_hash[key] = case value
                           when Hash
                             LazyValueHash.new(value)
                           when Array
                             LazyValueArray.new(value)
                           else
                             LazyValue.new(value)
                           end
      end
    end
  end
end
