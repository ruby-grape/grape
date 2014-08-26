module Grape
  module Util
    class InheritableValues
      attr_accessor :inherited_values
      attr_accessor :new_values

      def initialize(inherited_values = {})
        self.inherited_values = inherited_values
        self.new_values = LoggingValue.new
      end

      def [](name)
        values[name]
      end

      def []=(name, value)
        new_values[name] = value
      end

      def delete(key)
        new_values.delete key
      end

      def merge(new_hash)
        values.merge(new_hash)
      end

      def keys
        (new_values.keys + inherited_values.keys).sort.uniq
      end

      def to_hash
        values.clone
      end

      def initialize_copy(other)
        super
        self.inherited_values = other.inherited_values
        self.new_values = other.new_values.deep_dup
      end

      attr_writer :new_values

      protected

      def values
        result = LoggingValue.new

        @inherited_values.keys.each_with_object(result) do |(key), res|
          begin
            res[key] = @inherited_values[key].clone
          rescue
            res[key] = @inherited_values[key]
          end
        end

        result.merge(@new_values)
      end
    end
  end
end
