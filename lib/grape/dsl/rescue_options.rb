# frozen_string_literal: true

module Grape
  module DSL
    # Immutable value object holding the response-shaping booleans accepted
    # by +Grape::DSL::RequestResponse#rescue_from+. Recorded on the
    # inheritable settings via +Grape::Util::InheritableSetting#add_rescue_options+
    # (the nearest scope's latest registration wins on read, see
    # +#rescue_options+) and delegated to by +Grape::Middleware::Error+ (which forwards
    # +backtrace+/+original_exception+ to the formatter as
    # +include_backtrace+/+include_original_exception+).
    #
    # Defaults are duplicated on +#initialize+ here and on +#rescue_from+'s
    # signature on purpose: keeping them on both sides means each entry point
    # is self-documenting without needing to import a shared constant — the
    # DSL signature shows what a user sees in the IDE, and the Data object
    # has working defaults when constructed directly (middleware
    # `DEFAULT_OPTIONS`, spec fixtures, etc.). The two must stay in lockstep.
    RescueOptions = Data.define(:backtrace, :original_exception) do
      def initialize(backtrace: false, original_exception: false)
        super
      end
    end
  end
end
