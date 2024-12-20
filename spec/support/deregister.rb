# frozen_string_literal: true

module Deregister
  def deregister(key)
    registry.delete(key)
  end
end
