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
      #   - Classes / Modules — shared constants that must remain open
      #   - Coercers and ParamsScope — self-freeze at construction
      def deep_freeze(obj)
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
