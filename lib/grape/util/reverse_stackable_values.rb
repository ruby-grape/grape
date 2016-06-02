module Grape
  module Util
    class ReverseStackableValues
      attr_accessor :inherited_values
      attr_accessor :new_values

      def initialize(inherited_values = {})
        @inherited_values = inherited_values
        @new_values = {}
      end

      def [](name)
        [].tap do |value|
          value.concat(@new_values[name] || [])
          value.concat(@inherited_values[name] || [])
        end
      end

      def []=(name, value)
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

      def initialize_copy(other)
        super
        self.inherited_values = other.inherited_values
        self.new_values = other.new_values.dup
      end
    end
  end
end
