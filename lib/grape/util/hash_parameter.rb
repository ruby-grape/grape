require 'active_support/concern'
module Grape
  module Util
    module HashParameter
      extend ActiveSupport::Concern

      def deem_hash_array?(hash)
        return false unless hash.is_a?(Hash) && hash.keys.any? { |key| integer_string?(key) }
        true
      end

      def integer_string?(str)
        Integer(str)
        true
      rescue ArgumentError, TypeError
        false
      end
    end
  end
end
