require 'active_support/concern'

module Grape
  module DSL
    module Callbacks
      extend ActiveSupport::Concern

      module ClassMethods
        def before(&block)
          imbue(:befores, [block])
        end

        def before_validation(&block)
          imbue(:before_validations, [block])
        end

        def after_validation(&block)
          imbue(:after_validations, [block])
        end

        def after(&block)
          imbue(:afters, [block])
        end
      end
    end
  end
end
