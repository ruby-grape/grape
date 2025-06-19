# frozen_string_literal: true

Warning[:deprecated] = true

module DeprecatedWarningHandler
  class DeprecationWarning < StandardError; end

  DEPRECATION_REGEX = /is deprecated/

  def warn(message)
    return super unless message.match?(DEPRECATION_REGEX)

    exception = DeprecationWarning.new(message)
    exception.set_backtrace(caller)
    raise exception
  end
end

Warning.singleton_class.prepend(DeprecatedWarningHandler)
