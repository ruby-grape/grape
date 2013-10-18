module Grape
  module Util
    # HashStack is a stack of hashes. When retrieving a value, keys of the top
    # hash on the stack take precendent over the lower keys.
    class HashStack
      # Unmerged array of hashes to represent the stack.
      # The top of the stack is the last element.
      attr_reader :stack

      # TODO: handle aggregates
      def initialize
        @stack = [{}]
      end

      # Returns the top hash on the stack
      def peek
        @stack.last
      end

      # Add a new hash to the top of the stack.
      #
      # @param hash [Hash] optional hash to be pushed. Defaults to empty hash
      # @return [HashStack]
      def push(hash = {})
        @stack.push(hash)
        self
      end

      def pop
        @stack.pop
      end

      # Looks through the stack for the first frame that matches :key
      #
      # @param key [Symbol] key to look for in hash frames
      # @return value of given key after merging the stack
      def get(key)
        (@stack.length - 1).downto(0).each do |i|
          return @stack[i][key] if @stack[i].key? key
        end
        nil
      end
      alias_method :[], :get

      # Looks through the stack for the first frame that matches :key
      #
      # @param key [Symbol] key to look for in hash frames
      # @return true if key exists, false otherwise
      def has_key?(key)
        (@stack.length - 1).downto(0).each do |i|
          return true if @stack[i].key? key
        end
        false
      end

      # Replace a value on the top hash of the stack.
      #
      # @param key [Symbol] The key to set.
      # @param value [Object] The value to set.
      def set(key, value)
        peek[key.to_sym] = value
      end
      alias_method :[]=, :set

      # Replace multiple values on the top hash of the stack.
      #
      # @param hash [Hash] Hash of values to be merged in.
      def update(hash)
        peek.merge!(hash)
        self
      end

      # Adds addition value into the top hash of the stack
      def imbue(key, value)
        current = peek[key.to_sym]
        if current.is_a?(Array)
          current.concat(value)
        elsif current.is_a?(Hash)
          current.merge!(value)
        else
          set(key, value)
        end
      end

      # Prepend another HashStack's to self
      def prepend(hash_stack)
        @stack.unshift(*hash_stack.stack)
        self
      end

      # Concatenate another HashStack's to self
      def concat(hash_stack)
        @stack.concat hash_stack.stack
        self
      end

      # Looks through the stack for all instances of a given key and returns
      # them as a flat Array.
      #
      # @param key [Symbol] The key to gather
      # @return [Array]
      def gather(key)
        stack.map { |s| s[key] }.flatten.compact.uniq
      end

      def to_s
        @stack.to_s
      end

      def clone
        new_stack = HashStack.new
        stack.each do |frame|
          new_stack.push frame.clone
        end
        new_stack.stack.shift
        new_stack
      end
    end
  end
end
