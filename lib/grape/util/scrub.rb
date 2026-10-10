# frozen_string_literal: true

module Grape
  module Util
    # Outside input -- a param, a header, a query value, a body a route sets
    # -- can hold bytes its encoding does not allow: a query string
    # percent-encoding half a character, say. Much of String raises on such a
    # value (+blank?+'s whitespace regexp, +match?+, +downcase+), so it is
    # scrubbed, or asked about through {.blank?}, before anything else reads
    # it.
    #
    # Called on the module rather than included: an included +blank?+ that
    # takes an argument would shadow +Object#blank?+, which +present?+ calls.
    module Scrub
      # +value+ with each invalid byte replaced, or +value+ itself when it
      # holds none or is not a String.
      def self.scrub(value)
        return value if !value.respond_to?(:valid_encoding?) || value.valid_encoding?

        value.scrub
      end

      # +value.blank?+, answered without the copy +scrub(value).blank?+ would
      # build: a String holding an invalid byte is never blank, since an
      # invalid byte is not whitespace.
      def self.blank?(value)
        return false if value.is_a?(String) && !value.valid_encoding?

        value.blank?
      end
    end
  end
end
