# frozen_string_literal: true

module Grape
  module ErrorFormatter
    extend Grape::Util::Registry

    module_function

    def formatter_for(format, error_formatters = nil, default_error_formatter = nil)
      return error_formatters[format] if error_formatters&.key?(format)

      registry[format] || default_error_formatter || Grape::ErrorFormatter::Txt
    end
  end
end
