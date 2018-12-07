module Grape
  module Config
    module SettingStore
      ATTRIBUTES = %i[
        param_builder
      ].freeze

      attr_accessor(*SettingStore::ATTRIBUTES)

      def reset
        self.param_builder = Grape::Extensions::ActiveSupport::HashWithIndifferentAccess::ParamBuilder
      end

      def configure
        block_given? ? yield(self) : self
      end

      def config
        self
      end
    end

    Grape::Config.extend SettingStore
  end
end

Grape::Config.reset
