# frozen_string_literal: true

module Grape
  module DSL
    module Logger
      # Set or retrive the configured logger. If none was configured, this
      # method will create a new one, logging to stdout.
      # @param logger [Object] the new logger to use
      def logger(logger = nil)
        global_settings = inheritable_setting.global
        if logger
          global_settings[:logger] = logger
        else
          global_settings[:logger] || global_settings[:logger] = ::Logger.new($stdout)
        end
      end
    end
  end
end
