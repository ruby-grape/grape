# frozen_string_literal: true

module Grape
  module Util
    # Base class for the lazily-filled lookup caches (coercers, dry-types,
    # path parts, ...). Subclasses assign a default-block +Hash+ to +@cache+
    # in their +initialize+.
    #
    # Lookups are synchronized: caches are written at API *definition* time
    # (a +params+ block runs when the class body is evaluated), which is not
    # covered by the compile-time +Grape::API::Instance::LOCK+ and can happen
    # concurrently — e.g. parallel eager loading, or two threads autoloading
    # different API files. A +Monitor+ (reentrant) rather than a +Mutex+,
    # because a cache miss may re-enter the same cache: building a
    # multiple-type coercer through +Types::CoercerCache+ builds its member
    # coercers through +Types.build_coercer+, which lands in the same cache.
    class Cache
      include Singleton

      attr_reader :cache

      def initialize
        @monitor = Monitor.new
      end

      def [](key)
        @monitor.synchronize { @cache[key] }
      end

      class << self
        extend Forwardable

        def_delegators :instance, :[], :cache
      end
    end
  end
end
