# frozen_string_literal: true

module Grape
  module DSL
    module Callbacks
      # before: execute the given block before validation, coercion, or any endpoint
      # before_validation: execute the given block after `before`, but prior to validation or coercion
      # after_validation: execute the given block after validations and coercions, but before any endpoint code
      # after: execute the given block after the endpoint code has run except in unsuccessful
      # finally: execute the given block after the endpoint code even if unsuccessful

      %w[before before_validation after_validation after finally].each do |callback_method|
        define_method callback_method.to_sym do |&block|
          inheritable_setting.namespace_stackable[callback_method.pluralize.to_sym] = block
        end
      end
    end
  end
end
