require 'active_support/concern'

module Grape
  module DSL
    module Configuration
      extend ActiveSupport::Concern

      module ClassMethods
        attr_writer :logger
        attr_reader :settings

        def logger(logger = nil)
          if logger
            @logger = logger
          else
            @logger ||= Logger.new($stdout)
          end
        end

        # Add a description to the next namespace or function.
        def desc(description, options = {})
          @last_description = options.merge(description: description)
        end
      end
    end
  end
end
