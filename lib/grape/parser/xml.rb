# frozen_string_literal: true

module Grape
  module Parser
    class Xml < Base
      def self.call(object, _env)
        ::Grape::Xml.parse(object)
      rescue ::Grape::Xml::ParseError
        # handle XML parsing errors via the rescue handlers or provide error message
        raise Grape::Exceptions::InvalidMessageBody.new('application/xml')
      end
    end
  end
end
