# frozen_string_literal: true

module Grape
  module Util
    module PathNormalizer
      # Taken from Rails
      #     call("/foo")  # => "/foo"
      #     call("/foo/") # => "/foo"
      #     call("foo")   # => "/foo"
      #     call("")      # => "/"
      #     call("/%ab")  # => "/%AB"
      # https://github.com/rails/rails/blob/00cc4ff0259c0185fe08baadaa40e63ea2534f6e/actionpack/lib/action_dispatch/journey/router/utils.rb#L19
      def self.call(path)
        return '/' unless path
        return path if path == '/'

        # Fast path for the overwhelming majority of paths that don't need to be
        # normalized. Two String#include? calls rather than one `%|//` regexp:
        # same predicate, and the scan stays in C without building a match.
        return path if path.start_with?('/') && !(path.end_with?('/') || path.include?('%') || path.include?('//'))

        # Slow path
        encoding = path.encoding
        path = "/#{path}"
        path.squeeze!('/')

        unless path == '/'
          path.delete_suffix!('/')
          path.gsub!(/(%[a-f0-9]{2})/) { ::Regexp.last_match(1).upcase }
        end

        path.force_encoding(encoding)
      end
    end
  end
end
