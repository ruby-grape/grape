module Grape
  module Util
    class StackableValues
      attr_accessor :inherited_values
      attr_accessor :new_values
      attr_reader :frozen_values

      def initialize(inherited_values = {})
        @inherited_values = inherited_values
        @new_values = {}
        @frozen_values = {}
      end

      def [](name)
        return @frozen_values[name] if @frozen_values.key? name

        value = []
        value.concat(@inherited_values[name] || [])
        value.concat(@new_values[name] || [])
        value
      end

      def []=(name, value)
        raise if @frozen_values.key? name
        @new_values[name] ||= []
        @new_values[name].push value
      end

      def delete(key)
        new_values.delete key
      end

      def keys
        (@new_values.keys + @inherited_values.keys).sort.uniq
      end

      def to_hash
        keys.each_with_object({}) do |key, result|
          result[key] = self[key]
        end
      end

      def freeze_value(key)
        @frozen_values[key] = self[key].freeze
      end

      def initialize_copy(other)
        super
        self.inherited_values = other.inherited_values
        self.new_values = other.new_values.dup
      end
    end
  end
end
