# frozen_string_literal: true

module Deregister
  # A registration lives under both its String and its Symbol spelling
  # (see Grape::Util::Registry#register), so undoing one takes both.
  def deregister(key)
    registry.delete(key.to_s)
    registry.delete(key.to_sym)
  end
end
