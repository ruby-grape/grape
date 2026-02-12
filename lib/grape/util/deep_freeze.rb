# frozen_string_literal: true

module Grape
  module Util
    module DeepFreeze
      module_function

      # Recursively freezes Hash (keys and values), Array (elements), and String
      # objects. All other types are returned as-is.
      #
      # Intentionally left unfrozen:
      #   - Procs / lambdas — may be deferred DB-backed callables
      #   - Coercers (e.g. ArrayCoercer) — use lazy ivar memoization at request time
      #   - Classes / Modules — shared constants that must remain open
      #   - ParamsScope — self-freezes at the end of its own initialize
      def deep_freeze(obj)
        return obj if obj.frozen?

        case obj
        when Hash
          obj.each do |k, v|
            deep_freeze(k)
            deep_freeze(v)
          end
          obj.freeze
        when Array
          obj.each { |v| deep_freeze(v) }
          obj.freeze
        when String
          obj.freeze
        else
          obj
        end
      end
    end
  end
end
