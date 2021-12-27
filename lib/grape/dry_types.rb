# frozen_string_literal: true

require 'dry-types'

module Grape
  module DryTypes
    # Call +Dry.Types()+ to add all registered types to +DryTypes+ which is
    # a container in this case. Check documentation for more information
    # https://dry-rb.org/gems/dry-types/1.2/getting-started/
    include Dry.Types()
  end
end
