module Grape
  module Extensions
    module DeepSymbolizeHash
      def self.deep_symbolize_keys_in(object)
        case object
        when ::Hash
          object.each_with_object({}) do |(key, value), new_hash|
            new_hash[symbolize_key(key)] = deep_symbolize_keys_in(value)
          end
        when ::Array
          object.map { |element| deep_symbolize_keys_in(element) }
        else
          object
        end
      end

      def self.symbolize_key(key)
        key.respond_to?(:to_sym) ? key.to_sym : key
      end
    end
  end
end
