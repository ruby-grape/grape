require 'active_support/concern'

module Grape
  module DSL
    module Configuration
      extend ActiveSupport::Concern

      module ClassMethods
        attr_writer :logger
        # attr_reader :settings

        include Grape::DSL::Settings

        def logger(logger = nil)
          if logger
            global_setting(:logger, logger)
          else
            global_setting(:logger, Logger.new($stdout)) unless global_setting(:logger)
            global_setting(:logger)
          end
        end

        # Add a description to the next namespace or function.
        def desc(description, options = {})
          namespace_setting :description, options.merge(description: description)
          route_setting :description, options.merge(description: description)
        end
      end

      module_function

      def stacked_hash_to_hash(settings)
        return nil if settings.nil? || settings.blank?
        settings.each_with_object(ActiveSupport::OrderedHash.new) { |value, result| result.deep_merge!(value) }
      end
    end
  end
end
