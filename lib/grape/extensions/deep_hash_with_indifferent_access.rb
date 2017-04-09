module Grape
  module Extensions
    module DeepHashWithIndifferentAccess
      def self.deep_hash_with_indifferent_access(object)
        case object
        when ::Hash
          object.inject(::ActiveSupport::HashWithIndifferentAccess.new) do |new_hash, (key, value)|
            new_hash.merge!(key => deep_hash_with_indifferent_access(value))
          end
        when ::Array
          object.map { |element| deep_hash_with_indifferent_access(element) }
        else
          object
        end
      end
    end
  end
end
