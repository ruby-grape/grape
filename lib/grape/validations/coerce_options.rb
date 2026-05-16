# frozen_string_literal: true

module Grape
  module Validations
    # Immutable value object describing how a parameter is coerced. Assembled
    # by {ValidationsSpec#coerce_options} from the parsed +type+/+coerce_with+/
    # +coerce_message+ declaration — never written by the user — and consumed
    # by {ParamsScope#check_coerce_with} / {ParamsScope#validate_coerce} and by
    # {Validators::Validators::CoerceValidator} (which receives it as its
    # +options+ argument).
    #
    # All three fields may be +nil+ (e.g. a remountable API evaluated on its
    # base instance has no resolved +type+ yet).
    # +coerce_method+ (not +method+) avoids shadowing +Object#method+.
    CoerceOptions = Data.define(:type, :coerce_method, :message) do
      def initialize(type: nil, coerce_method: nil, message: nil)
        super
      end
    end
  end
end
