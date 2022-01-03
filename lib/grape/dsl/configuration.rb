# frozen_string_literal: true

module Grape
  module DSL
    module Configuration
      extend ActiveSupport::Concern

      module ClassMethods
        include Grape::DSL::Settings
        include Grape::DSL::Logger
        include Grape::DSL::Desc
      end
    end
  end
end
