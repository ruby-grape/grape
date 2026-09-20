# frozen_string_literal: true

module Deregister
  # A registration lives under both its String and its Symbol spelling
  # (see Grape::Util::Registry#register), so undoing one takes both.
  # Registration replaces the registry rather than writing into it, and the
  # replacement is frozen, so undoing one replaces it in turn.
  def deregister(key)
    @registry = registry.except(key.to_s, key.to_sym).freeze
  end
end
