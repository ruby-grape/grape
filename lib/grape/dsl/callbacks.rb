# frozen_string_literal: true

module Grape
  module DSL
    module Callbacks
      # before: execute the given block before validation, coercion, or any endpoint
      # before_validation: execute the given block after `before`, but prior to validation or coercion
      # after_validation: execute the given block after validations and coercions, but before any endpoint code
      # after: execute the given block after the endpoint code has run except in unsuccessful
      # finally: execute the given block after the endpoint code even if unsuccessful

      %i[before before_validation after_validation after finally].each do |callback_name|
        define_method callback_name do |&block|
          inheritable_setting.add_callback(callback_name, block)
        end
      end
    end
  end
end
