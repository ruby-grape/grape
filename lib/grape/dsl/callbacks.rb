# frozen_string_literal: true

module Grape
  module DSL
    module Callbacks
      # before: execute the given block before validation, coercion, or any endpoint
      # before_validation: execute the given block after `before`, but prior to validation or coercion
      # after_validation: execute the given block after validations and coercions, but before any endpoint code
      # after: execute the given block after the endpoint code has run except in unsuccessful
      # finally: execute the given block after the endpoint code even if unsuccessful

      {
        before: :befores,
        before_validation: :before_validations,
        after_validation: :after_validations,
        after: :afters,
        finally: :finallies
      }.each do |method_name, plural_key|
        define_method method_name do |&block|
          inheritable_setting.namespace_stackable[plural_key] = block
        end
      end
    end
  end
end
