# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class AsValidator < Base
        # Never dispatched: +as:+ renaming is handled by ParamsScope. No
        # validation happens here.
        def validate_param!(*); end
      end
    end
  end
end
