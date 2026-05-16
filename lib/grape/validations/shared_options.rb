# frozen_string_literal: true

module Grape
  module Validations
    # Immutable value object holding the two options every validator reads at
    # construction time: +allow_blank+ and +fail_fast+. Internal to
    # {Validators::Base}, which builds it from the +opts+ Hash so the public
    # 5th-argument contract stays a plain Hash — not part of any wire contract.
    #
    # Defaults mirror the prior +opts.values_at+ behaviour: +allow_blank+ is
    # +nil+ when the declaration didn't supply it (validators treat nil as
    # "not set"), +fail_fast+ defaults to +false+.
    SharedOptions = Data.define(:allow_blank, :fail_fast) do
      def initialize(allow_blank: nil, fail_fast: false)
        super
      end
    end
  end
end
