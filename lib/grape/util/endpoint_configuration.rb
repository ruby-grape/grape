# frozen_string_literal: true

module Grape
  module Util
    # The +with:+ Hash a mount supplies, read as a {Grape::Util::Lazy::Value} so
    # that reads taken before the mount happened can be replayed against it
    # afterwards. Keys are indifferent at every depth.
    class EndpointConfiguration < Lazy::Value
      def initialize(config)
        super(config.with_indifferent_access)
      end
    end
  end
end
