module Grape
  module Middleware
    # Class to handle the stack of middlewares based on ActionDispatch::MiddlewareStack
    # It allows to insert and insert after
    class Stack
      class Middleware
        attr_reader :args, :block, :klass

        def initialize(klass, *args, &block)
          @klass = klass
          @args = args
          @block = block
        end

        def name
          klass.name
        end

        def ==(other)
          case other
          when Middleware
            klass == other.klass
          when Class
            klass == other
          end
        end

        def inspect
          klass.to_s
        end
      end

      include Enumerable

      attr_accessor :middlewares

      def initialize
        @middlewares = []
      end

      def each
        @middlewares.each { |x| yield x }
      end

      def size
        middlewares.size
      end

      def last
        middlewares.last
      end

      def [](i)
        middlewares[i]
      end

      def insert(index, *args, &block)
        index = assert_index(index, :before)
        middleware = self.class::Middleware.new(*args, &block)
        middlewares.insert(index, middleware)
      end

      alias insert_before insert

      def insert_after(index, *args, &block)
        index = assert_index(index, :after)
        insert(index + 1, *args, &block)
      end

      def use(*args, &block)
        middleware = self.class::Middleware.new(*args, &block)
        middlewares.push(middleware)
      end

      def merge_with(other)
        other.each do |operation, *args|
          block = args.pop if args.last.is_a?(Proc)
          block ? send(operation, *args, &block) : send(operation, *args)
        end
      end

      def build(builder)
        middlewares.each do |m|
          m.block ? builder.use(m.klass, *m.args, &m.block) : builder.use(m.klass, *m.args)
        end
      end

      protected

      def assert_index(index, where)
        i = index.is_a?(Integer) ? index : middlewares.index(index)
        raise "No such middleware to insert #{where}: #{index.inspect}" unless i
        i
      end
    end
  end
end
