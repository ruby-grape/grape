# frozen_string_literal: true

module Grape
  module Middleware
    # Mixin for per-middleware +Options+ +Data+ classes that need to keep
    # accepting legacy +data[:key]+ Hash-style access while nudging callers
    # toward the named accessor. Emits a +Grape.deprecator+ warning then
    # forwards to +public_send(key)+.
    module DeprecatedOptionsHashAccess
      def [](key)
        Grape.deprecator.warn(
          "`#{self.class.name}#[]` is deprecated. " \
          "Use the named accessor `#{key}` instead."
        )
        public_send(key) if members.include?(key)
      end
    end
  end
end
