# frozen_string_literal: true

module Grape
  module Middleware
    # Class to handle the stack of middlewares based on ActionDispatch::MiddlewareStack
    # It allows to insert and insert after
    class Stack
      class Middleware
        attr_reader :args, :opts, :block, :klass

        def initialize(klass, *args, **opts, &block)
          @klass = klass
          @args  = args
          @opts  = opts
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
            klass == other || (name.nil? && klass.superclass == other)
          end
        end

        def inspect
          klass.to_s
        end

        if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.7')
          def use_in(builder)
            block ? builder.use(klass, *args, **opts, &block) : builder.use(klass, *args, **opts)
          end
        else
          def use_in(builder)
            args  = self.args
            args += [opts] unless opts.empty?
            block ? builder.use(klass, *args, &block) : builder.use(klass, *args)
          end
        end
      end

      include Enumerable

      attr_accessor :middlewares, :others

      def initialize
        @middlewares = []
        @others = []
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

      def insert(index, *args, **kwargs, &block)
        index = assert_index(index, :before)
        middleware = self.class::Middleware.new(*args, **kwargs, &block)
        middlewares.insert(index, middleware)
      end

      alias insert_before insert

      def insert_after(index, *args, &block)
        index = assert_index(index, :after)
        insert(index + 1, *args, &block)
      end

      def use(*args, **kwargs, &block)
        middleware = self.class::Middleware.new(*args, **kwargs, &block)
        middlewares.push(middleware)
      end

      def merge_with(middleware_specs)
        middleware_specs.each do |operation, *args|
          if args.last.is_a?(Proc)
            last_proc = args.pop
            public_send(operation, *args, &last_proc)
          else
            public_send(operation, *args)
          end
        end
      end

      # @return [Rack::Builder] the builder object with our middlewares applied
      def build(builder = Rack::Builder.new)
        others.shift(others.size).each(&method(:merge_with))
        middlewares.each do |m|
          m.use_in(builder)
        end
        builder
      end

      # @description Add middlewares with :use operation to the stack. Store others with :insert_* operation for later
      # @param [Array] other_specs An array of middleware specifications (e.g. [[:use, klass], [:insert_before, *args]])
      def concat(other_specs)
        @others << Array(other_specs).reject { |o| o.first == :use }
        merge_with(Array(other_specs).select { |o| o.first == :use })
      end

      protected

      def assert_index(index, where)
        i = index.is_a?(Integer) ? index : middlewares.index(index)
        i || raise("No such middleware to insert #{where}: #{index.inspect}")
      end
    end
  end
end
