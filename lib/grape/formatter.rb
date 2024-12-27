# frozen_string_literal: true

module Grape
  module Formatter
    extend Grape::Util::Registry

    module_function

    DEFAULT_LAMBDA_FORMATTER = ->(obj, _env) { obj }

    def formatter_for(api_format, formatters)
      return formatters[api_format] if formatters&.key?(api_format)

      registry[api_format] || DEFAULT_LAMBDA_FORMATTER
    end
  end
end
