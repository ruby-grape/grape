# frozen_string_literal: true

module Grape
  module ErrorFormatter
    class Json < Base
      class << self
        def format_structured_message(structured_message)
          ::Grape::Json.dump(structured_message)
        end

        private

        def wrap_message(message)
          # Use +is_a?+ rather than +case/when+ here. +case/when Hash+ matches via
          # +Module#===+, a C-level real-class check that ignores delegation, so a
          # +SimpleDelegator+ wrapping a Hash (e.g. the +OutputBuilder+ returned by
          # +Grape::Entity#serializable_hash+ when an error is presented via an entity)
          # would fall through and be wrapped in a spurious +{ error: ... }+ envelope.
          # +is_a?+ is forwarded by the delegator to the wrapped Hash, so it matches.
          return message if message.is_a?(Hash)
          return message.as_json if message.is_a?(Exceptions::ValidationErrors)

          { error: ensure_utf8(message) }
        end

        # Re-encoding a String that already is valid UTF-8 only copies it, for
        # about 260 ns on every error response.
        def ensure_utf8(message)
          return message unless message.respond_to? :encode
          return message if message.is_a?(String) && message.encoding == Encoding::UTF_8 && message.valid_encoding?

          message.encode('UTF-8', invalid: :replace, undef: :replace)
        end
      end
    end
  end
end
