module Grape
  module Util
    class LoggingValue
      attr_accessor :container

      def initialize
        self.container = {}
      end

      def [](name)
        container[name]
      end

      def []=(name, value)
        container[name] = value
      end

      def delete(key)
        container.delete key
      end

      def merge(new_hash)
        container.merge(new_hash)
      end

      def keys
        container.keys
      end

      def to_hash
        container.to_hash
      end

      def initialize_copy(other)
        super
        self.container = other.container.clone
      end
    end
  end
end
