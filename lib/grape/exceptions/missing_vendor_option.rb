# encoding: utf-8
module Grape
  module Exceptions
    class MissingVendorOption < Base
      def initialize
        super(message: compose_message(:missing_vendor_option))
      end
    end
  end
end
