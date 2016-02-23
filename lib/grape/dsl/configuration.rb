require 'active_support/concern'

module Grape
  module DSL
    module Configuration
      extend ActiveSupport::Concern

      module ClassMethods
        include Grape::DSL::Settings
        include Grape::DSL::Logger
        include Grape::DSL::Desc
      end

      module_function

      # Merge multiple layers of settings into one hash.
      def stacked_hash_to_hash(settings)
        return if settings.blank?
        settings.each_with_object({}) { |value, result| result.deep_merge!(value) }
      end
    end
  end
end
