# frozen_string_literal: true

module Grape
  module DSL
    module Logger
      # Set or retrieve the configured logger. If none was configured, this
      # method will create a new one, logging to stdout.
      #
      # A logger belongs to the API it is set on, and to the APIs mounted
      # under it that set none of their own. It used to be kept in the
      # process-wide settings, so setting one on any API replaced it on every
      # other. Only the default is still shared: an API that sets a level on
      # it at class level reads it off its base instance, and has to find
      # that level again on each instance it is mounted as.
      # @param logger [Object] the new logger to use
      def logger(logger = nil)
        return top_level_setting.logger = logger if logger

        top_level_setting.logger || (inheritable_setting.global[:logger] ||= ::Logger.new($stdout))
      end
    end
  end
end
