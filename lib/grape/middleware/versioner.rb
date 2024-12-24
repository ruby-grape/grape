# frozen_string_literal: true

# Versioners set env['api.version'] when a version is defined on an API and
# on the requests. The current methods for determining version are:
#
#   :header - version from HTTP Accept header.
#   :accept_version_header - version from HTTP Accept-Version header
#   :path   - version from uri. e.g. /v1/resource
#   :param  - version from uri query string, e.g. /v1/resource?apiver=v1
# See individual classes for details.
module Grape
  module Middleware
    module Versioner
      extend Grape::Util::Registry

      module_function

      # @param strategy [Symbol] :path, :header, :accept_version_header or :param
      # @return a middleware class based on strategy
      def using(strategy)
        raise Grape::Exceptions::InvalidVersionerOption, strategy unless registry.key?(strategy)

        registry[strategy]
      end
    end
  end
end
