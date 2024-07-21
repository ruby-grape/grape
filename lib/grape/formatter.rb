# frozen_string_literal: true

module Grape
  module Formatter
    module_function

    DEFAULTS = {
      json: Grape::Formatter::Json,
      jsonapi: Grape::Formatter::Json,
      serializable_hash: Grape::Formatter::SerializableHash,
      txt: Grape::Formatter::Txt,
      xml: Grape::Formatter::Xml
    }.freeze

    DEFAULT_LAMBDA_FORMATTER = ->(obj, _env) { obj }

    def formatter_for(api_format, formatters)
      select_formatter(formatters, api_format) || DEFAULT_LAMBDA_FORMATTER
    end

    def select_formatter(formatters, api_format)
      formatters&.key?(api_format) ? formatters[api_format] : DEFAULTS[api_format]
    end
  end
end
