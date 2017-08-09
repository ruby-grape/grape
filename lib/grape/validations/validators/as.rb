module Grape
  module Validations
    class AsValidator < Base
      def initialize(attrs, options, required, scope, opts = {})
        @alias = options
        super
      end

      def validate_param!(attr_name, params)
        params[@alias] = params[attr_name]
        params.delete(attr_name)
      end
    end
  end
end
