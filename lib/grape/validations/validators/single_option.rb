module Grape
  module Validations
    class SingleOptionValidator < Base
      def initialize(attrs, options, required, scope)
        @option = options
        super
      end
    end
  end
end
