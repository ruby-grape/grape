# frozen_string_literal: true

module Grape
  module DSL
    module Middleware
      # Apply a custom middleware to the API. Applies
      # to the current namespace and any children, but
      # not parents.
      #
      # @param middleware_class [Class] The class of the middleware you'd like
      #   to inject.
      def use(middleware_class, *args, &block)
        inheritable_setting.add_middleware([:use, middleware_class, *args, block])
      end

      %i[insert insert_before insert_after].each do |method_name|
        define_method method_name do |*args, &block|
          inheritable_setting.add_middleware([method_name, *args, block])
        end
      end

      # Retrieve an array of the middleware classes
      # and arguments that are currently applied to the
      # application, each ending in the block it was
      # given, +nil+ when none.
      def middleware
        inheritable_setting.middleware
      end
    end
  end
end
