# frozen_string_literal: true

module Grape
  module Middleware
    # Class to handle the stack of middlewares based on ActionDispatch::MiddlewareStack
    # It allows to insert and insert after
    class Stack
      extend Forwardable

      class Middleware
        attr_reader :args, :block, :klass

        def initialize(klass, args, block)
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
            klass == other || (name.nil? && klass.superclass == other)
          end
        end

        def inspect
          klass.to_s
        end

        def build(builder)
          # we need to force the ruby2_keywords_hash for middlewares that initialize contains keywords
          # like ActionDispatch::RequestId since middleware arguments are serialized
          # https://rubyapi.org/3.4/o/hash#method-c-ruby2_keywords_hash
          args[-1] = Hash.ruby2_keywords_hash(args[-1]) if args.last.is_a?(Hash) && Hash.respond_to?(:ruby2_keywords_hash)
          builder.use(klass, *args, &block)
        end
      end

      include Enumerable

      attr_accessor :middlewares, :others

      def_delegators :middlewares, :each, :size, :last, :[]

      def initialize
        @middlewares = []
        @others = []
      end

      def insert(index, klass, *args, &block)
        index = assert_index(index, :before)
        middlewares.insert(index, self.class::Middleware.new(klass, args, block))
      end

      alias insert_before insert

      def insert_after(index, ...)
        index = assert_index(index, :after)
        insert(index + 1, ...)
      end

      def use(klass, *args, &block)
        middleware = self.class::Middleware.new(klass, args, block)
        middlewares.push(middleware)
      end

      def merge_with(middleware_specs)
        middleware_specs.each do |operation, klass, *args|
          if args.last.is_a?(Proc)
            last_proc = args.pop
            public_send(operation, klass, *args, &last_proc)
          else
            public_send(operation, klass, *args)
          end
        end
      end

      # @return [Rack::Builder] the builder object with our middlewares applied
      def build
        Rack::Builder.new.tap do |builder|
          others.shift(others.size).each { |m| merge_with(m) }
          middlewares.each do |m|
            m.build(builder)
          end
        end
      end

      # @description Add middlewares with :use operation to the stack. Store others with :insert_* operation for later
      # @param [Array] other_specs An array of middleware specifications (e.g. [[:use, klass], [:insert_before, *args]])
      def concat(other_specs)
        use, not_use = other_specs.partition { |o| o.first == :use }
        others << not_use
        merge_with(use)
      end

      protected

      def assert_index(index, where)
        i = index.is_a?(Integer) ? index : middlewares.index(index)
        i || raise("No such middleware to insert #{where}: #{index.inspect}")
      end
    end
  end
end
