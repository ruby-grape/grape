# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class AsValidator < Base
        # We use a validator for renaming parameters. This is just a marker for
        # the parameter scope to handle the renaming. No actual validation
        # happens here.
        def validate_param!(*); end
      end
    end
  end
end
