# frozen_string_literal: true

module Grape
  module Util
    module Lazy
      class ValueEnumerable < Value
        def [](key)
          return Value.new(nil).reached_by(access_keys, key) if @value_hash[key].nil?

          @value_hash[key].reached_by(access_keys, key)
        end

        def fetch(access_keys)
          access_keys.reduce(self) { |node, key| node[key] }
        end

        def []=(key, value)
          value_class = case value
                        when Hash
                          ValueHash
                        when Array
                          ValueArray
                        else
                          Value
                        end
          @value_hash[key] = value_class.new(value)
        end
      end
    end
  end
end
