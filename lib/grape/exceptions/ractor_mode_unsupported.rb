# frozen_string_literal: true

module Grape
  module Exceptions
    class RactorModeUnsupported < Base
      def initialize
        super(message: compose_message(:ractor_mode_unsupported, ruby_version: RUBY_VERSION))
      end
    end
  end
end
