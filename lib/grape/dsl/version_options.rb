# frozen_string_literal: true

module Grape
  module DSL
    # Immutable value object holding the resolved options from
    # +Grape::DSL::Routing#version+. Stored on the inheritable settings as
    # +Grape::Util::InheritableSetting#version_options+ and read by internal call
    # sites (`Path`, `Endpoint`, `API::Instance#cascade?`,
    # `Middleware::Versioner::Base`) via accessors.
    #
    # Defaults are duplicated on +#initialize+ here and on +#version+'s
    # signature on purpose: keeping them on both sides means each entry point
    # is self-documenting without needing to import a shared constant — the
    # DSL signature shows what a user sees in the IDE, and the Data object
    # has working defaults when constructed directly (middleware
    # `DEFAULT_OPTIONS`, spec fixtures, etc.). The two must stay in lockstep.
    VersionOptions = Data.define(:using, :cascade, :parameter, :strict, :vendor) do
      def initialize(using: :path, cascade: true, parameter: 'apiver', strict: false, vendor: nil)
        super
      end
    end
  end
end
