# frozen_string_literal: true

module Grape
  module ErrorFormatter
    module_function

    DEFAULTS = {
      serializable_hash: Grape::ErrorFormatter::Json,
      json: Grape::ErrorFormatter::Json,
      jsonapi: Grape::ErrorFormatter::Json,
      txt: Grape::ErrorFormatter::Txt,
      xml: Grape::ErrorFormatter::Xml
    }.freeze

    def formatter_for(format, error_formatters = nil, default_error_formatter = nil)
      select_formatter(error_formatters, format) || default_error_formatter || DEFAULTS[:txt]
    end

    def select_formatter(error_formatters, format)
      error_formatters&.key?(format) ? error_formatters[format] : DEFAULTS[format]
    end
  end
end
