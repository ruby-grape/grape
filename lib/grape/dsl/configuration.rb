require 'active_support/concern'

module Grape
  module DSL
    module Configuration
      extend ActiveSupport::Concern

      module ClassMethods
        attr_writer :logger

        include Grape::DSL::Settings

        def logger(logger = nil)
          if logger
            global_setting(:logger, logger)
          else
            global_setting(:logger) || global_setting(:logger, Logger.new($stdout))
          end
        end

        # Add a description to the next namespace or function.
        def desc(description, options = {}, &config_block)
          if block_given?
            config_class = Grape::DSL::Configuration.desc_container

            config_class.configure do
              description description
            end

            config_class.configure(&config_block)
            options = config_class.settings
          else
            options = options.merge(description: description)
          end

          namespace_setting :description, options
          route_setting :description, options
        end
      end

      module_function

      def stacked_hash_to_hash(settings)
        return nil if settings.nil? || settings.blank?
        settings.each_with_object(ActiveSupport::OrderedHash.new) { |value, result| result.deep_merge!(value) }
      end

      def desc_container
        Module.new do
          include Grape::Util::StrictHashConfiguration.module(
            :description,
            :detail,
            :params,
            :entity,
            :http_codes,
            :named,
            :headers
          )

          def config_context.success(*args)
            entity(*args)
          end

          def config_context.failure(*args)
            http_codes(*args)
          end
        end
      end
    end
  end
end
