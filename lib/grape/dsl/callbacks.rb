require 'active_support/concern'

module Grape
  module DSL
    module Callbacks
      extend ActiveSupport::Concern

      include Grape::DSL::Configuration

      module ClassMethods
        def before(&block)
          namespace_stackable(:befores, block)
        end

        def before_validation(&block)
          namespace_stackable(:before_validations, block)
        end

        def after_validation(&block)
          namespace_stackable(:after_validations, block)
        end

        def after(&block)
          namespace_stackable(:afters, block)
        end
      end
    end
  end
end
