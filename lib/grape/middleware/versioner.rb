# Versioners set env['api.version'] when a version is defined on an API and
# on the requests. The current methods for determining version are:
#
#   :header - version from HTTP Accept header.
#   :path   - version from uri. e.g. /v1/resource
#
# See individual classes for details.
module Grape
  module Middleware
    module Versioner
      extend self

      # @param strategy [Symbol] :path or :header
      # @return a middleware class based on strategy
      def using(strategy)
        case strategy
        when :path
          Path
        when :header
          Header
        when :param
          Param
        else
          raise ArgumentError.new("Unknown :using for versioner: #{strategy}")
        end
      end
    end
  end
end