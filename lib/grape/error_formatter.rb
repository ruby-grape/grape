# frozen_string_literal: true

module Grape
  module ErrorFormatter
    extend Grape::Util::Registry

    module_function

    # Answers nil when nothing is registered for the format, the way
    # +Parser.parser_for+ does. What to fall back to then is the API's own
    # +default_error_formatter+, which is the caller's state rather than the
    # registry's: +Middleware::Error+ holds it and applies it.
    def formatter_for(format, error_formatters = nil)
      return error_formatters[format] if error_formatters&.key?(format)

      registry[format]
    end
  end
end
