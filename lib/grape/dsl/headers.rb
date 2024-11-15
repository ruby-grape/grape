# frozen_string_literal: true

module Grape
  module DSL
    module Headers
      # This method has four responsibilities:
      # 1. Set a specifc header value by key
      # 2. Retrieve a specifc header value by key
      # 3. Retrieve all headers that have been set
      # 4. Delete a specifc header key-value pair
      def header(key = nil, val = nil)
        if key
          if val
            warn "Header value for '#{key}' is not a string. Converting to string." unless val.is_a?(String)
            header[key.to_s] = val.to_s
          else
            header.delete(key.to_s)
          end
        else
          @header ||= Grape::Util::Header.new
        end
      end
      alias headers header
    end
  end
end
