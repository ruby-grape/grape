# frozen_string_literal: true

module Grape
  module Util
    # Diagnostics for +rescue_from+ registrations that can never run.
    #
    # Middleware::Error resolves with +find+, so within a scope the first
    # matching class wins and one registered for a class an earlier handler
    # already covers is dead code — silently, before this warned:
    #
    #   rescue_from StandardError do ... end   # wins
    #   rescue_from ArgumentError do ... end   # never runs
    #
    # Warn rather than reorder: which should win is the author's call, and
    # +rescue_from :all+ (consulted only after the registered handlers) already
    # offers "broad first, specific still wins" to anyone who wants it.
    module ShadowedRescueHandlers
      module_function

      # @param registered [Hash] the scope's own handlers, in registration order
      # @param mapping [Hash] the handlers being registered now
      # @return [void]
      #
      # Only a scope's own registrations are compared: across scopes the nearest
      # one deliberately wins, so an inner +rescue_from StandardError+ shadowing
      # an outer +rescue_from ArgumentError+ is the documented behaviour rather
      # than a mistake. Classes sharing a handler object are skipped too, since
      # +rescue_from A, B+ registers one handler for both and the entry that
      # loses to the other changes nothing.
      def warn_about(registered, mapping)
        return if registered.empty?

        mapping.each do |klass, handler|
          covered_by, = registered.find { |already, existing| klass <= already && !existing.equal?(handler) }
          next unless covered_by

          warn(message_for(klass, covered_by))
        end
      end

      def message_for(klass, covered_by)
        return "Grape: rescue_from #{klass} was already registered in this scope; the first handler is kept and this one will never run." if klass == covered_by

        "Grape: rescue_from #{klass} will never run — #{covered_by} was registered earlier in the same scope " \
          'and is matched first. Register the more specific class before the broader one.'
      end
    end
  end
end
