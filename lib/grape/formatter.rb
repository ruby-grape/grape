# frozen_string_literal: true

module Grape
  module Formatter
    extend Grape::Util::Registry

    module_function

    # Answers the body as it is, for a format nothing is registered for. A
    # module like the formatters registered here, rather than a lambda: a
    # lambda carries the self it was written under, so it cannot be frozen
    # all the way down.
    DEFAULT_LAMBDA_FORMATTER = Module.new do
      def self.call(obj, _env) = obj
    end

    def formatter_for(api_format, formatters)
      return formatters[api_format] if formatters&.key?(api_format)

      registry[api_format] || DEFAULT_LAMBDA_FORMATTER
    end
  end
end
