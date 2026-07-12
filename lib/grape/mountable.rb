# frozen_string_literal: true

module Grape
  # Marker module for a mountable Grape application. Both {Grape::API} (the
  # remountable user-facing class) and {Grape::API::Instance} (the compiled
  # engine) extend it, so a mounted Grape app can be told apart from a bare
  # Rack app with `is_a?(Grape::Mountable)` — a single, explicit predicate
  # rather than duck-typing on an incidental internal method such as
  # `inheritable_setting`.
  #
  # `Grape::API` and `Grape::API::Instance` are not related by inheritance and
  # do not even respond to the same methods (the former to `mount_instance`,
  # the latter to `inheritable_setting`/`endpoints`), so there is no common
  # ancestor to key an `is_a?` check on without this marker.
  #
  # It answers identity only ("is this a Grape app?"). Capability checks that
  # go on to call a stage-specific method — e.g. `respond_to?(:endpoints)`
  # before reading `endpoints` — must stay as they are, since a `Mountable`
  # does not necessarily respond to every such method.
  module Mountable
  end
end
