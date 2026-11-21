# frozen_string_literal: true

module Grape
  class Endpoint
    # The Rack app an endpoint's requests go through unless a bare Rack app is
    # mounted at it: the error middleware, the API's own middleware, the
    # versioner and the formatter, around the endpoint itself. Built once, at
    # compile time, from the endpoint's settings.
    module RackStack
      # The innermost app of every endpoint's Rack stack. The endpoint to run
      # comes out of the env, so the app holds no state and one of them serves
      # every stack, rather than one being allocated per endpoint. A module
      # rather than a lambda, which carries the self it was written under and
      # so cannot be frozen all the way down.
      module RunEndpoint
        def self.call(env) = env[Grape::Env::API_ENDPOINT].run
      end
      private_constant :RunEndpoint

      module_function

      def build(setting)
        stack = Grape::Middleware::Stack.new
        content_types = setting.content_types
        format = setting.format

        stack.use Grape::Middleware::Error, **error_middleware_options(setting, format, content_types)

        stack.concat setting.middleware
        use_versioner(stack, setting)
        stack.use Grape::Middleware::Formatter, **formatter_middleware_options(setting, format, content_types)

        builder = stack.build
        builder.run RunEndpoint
        builder.to_app
      end

      # The versioner for the strategy +version+ declared, when it declared one.
      def use_versioner(stack, setting)
        versions = setting.version
        return if versions.nil? || versions.empty?

        version_options = setting.version_options
        stack.use Grape::Middleware::Versioner.using(version_options.using),
                  versions: versions.flatten,
                  version_options:,
                  prefix: setting.root_prefix,
                  mount_path: setting.mount_path
      end

      def formatter_middleware_options(setting, format, content_types)
        {
          format:,
          default_format: setting.default_format || :txt,
          content_types:,
          formatters: setting.formatters,
          parsers: setting.parsers
        }
      end

      def error_middleware_options(setting, format, content_types)
        {
          format:,
          content_types:,
          default_status: setting.default_error_status,
          rescue_all: setting.rescue_all?,
          rescue_grape_exceptions: setting.rescue_grape_exceptions?,
          default_error_formatter: setting.default_error_formatter,
          error_formatters: setting.error_formatters,
          rescue_options: setting.rescue_options,
          rescue_handlers: setting.rescue_handlers,
          base_only_rescue_handlers: setting.base_only_rescue_handlers,
          all_rescue_handler: setting.all_rescue_handler,
          grape_exceptions_rescue_handler: setting.grape_exceptions_rescue_handler,
          internal_grape_exceptions_rescue_handler: setting.internal_grape_exceptions_rescue_handler
        }
      end
    end
  end
end
