# frozen_string_literal: true

module Grape
  module Util
    # Extend into a class whose instances are shared across requests:
    # +new+ returns a frozen instance, so any later ivar write — e.g.
    # request-time memoization — raises FrozenError instead of being a
    # latent data race.
    #
    # Must stay a +new+ wrapper (never an +initialize+ wrapper): the freeze
    # runs after the entire initialize chain, so subclasses may assign ivars
    # after +super+. Extending a hierarchy base covers its subclasses —
    # singleton classes inherit along the class hierarchy.
    module FreezeOnNew
      def new(...)
        super.freeze
      end
    end
  end
end
